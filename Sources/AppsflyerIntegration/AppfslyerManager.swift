import UIKit
import AppsFlyerLib

public class AppfslyerManager: NSObject {
    private enum ConversionResult {
        case success([AnyHashable: Any])
        case failure(Error)
    }

    public var delegate: AppsflyerManagerDelegate?
    public var deeplinkError: Error? = nil
    public var deeplinkResult: [String: String]? {
        get {
            return UserDefaults.standard.object(forKey: deepLinkResultUDKey) as? [String: String]
        }
        set {
            guard deeplinkResult == nil, newValue != nil else {
                return
            }

            UserDefaults.standard.set(newValue, forKey: deepLinkResultUDKey)
        }
    }

    private var deepLinkResultUDKey = "coreintegrations_appsflyer_deeplinkResult"

    /// `true` once a successful conversion result was delivered in this process. Unlike
    /// `deeplinkResult` it is not persisted, and a conversion failure does not set it.
    public private(set) var didDeliverConversionData = false

    /*
     SDK 7 no longer starts the session for us. `waitForATTUserAuthorization` used to
     hold the first session inside the SDK until ATT resolved; in 7.x the SDK explicitly
     does not manage ATT timing, so the session must be started by us once every
     precondition is met. The three gates below are those preconditions - see
     `startSessionIfReady()`. All of them are mutated on the main queue only.
     */
    private var isATTResolved = false
    private var isAdPartnersDataSharingEnabled = true
    private var isUserIDReady = false
    private var sessionStartPolicy = AppsFlyerSessionStartPolicy()
    private var sessionTally = AppsFlyerSessionTally()

    /*
     A failed start is worth exactly one report per install, and only while the SDK has never
     managed to start at all. The failure is entirely on the AppsFlyer side, so a broken
     `start` would otherwise have every user reporting on every cold launch; and once a
     session has ever gone through, later failures are not interesting. Both flags are
     persisted - surviving relaunches is the whole point.
     */
    private let didStartSuccessfullyUDKey = "coreintegrations_appsflyer_didStartSuccessfully"
    private let didReportStartFailureUDKey = "coreintegrations_appsflyer_didReportStartFailure"

    private var didEverStartSuccessfully: Bool {
        get { UserDefaults.standard.bool(forKey: didStartSuccessfullyUDKey) }
        set { UserDefaults.standard.set(newValue, forKey: didStartSuccessfullyUDKey) }
    }

    private var didReportStartFailure: Bool {
        get { UserDefaults.standard.bool(forKey: didReportStartFailureUDKey) }
        set { UserDefaults.standard.set(newValue, forKey: didReportStartFailureUDKey) }
    }

    public init(config: AppsflyerConfigData,
                launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        super.init()

#if DEBUG
        AppsFlyerLib.shared().isDebug = true
#else
        AppsFlyerLib.shared().isDebug = false
#endif
        AppsFlyerLib.shared().initialize(devKey: config.appsFlyerDevKey, appId: config.appleAppID)
        AppsFlyerLib.shared().delegate = self

        // Launch options have to be handed over before the session ready listener is
        // registered, otherwise a cold start Universal Link is not resolved before
        // readiness fires.
        AppsFlyerLib.shared().handleLaunchOptions(launchOptions)
        AppsFlyerLib.shared().registerSessionReadyListener { [weak self] in
            self?.updateGates {
                // AppsFlyer 7 owns lifecycle readiness. The listener re-fires on every activation
                // of the same foreground cycle, so it only marks readiness - see the start policy.
                $0.sessionStartPolicy.sessionBecameReady()
            }
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func applicationDidEnterBackground() {
        updateGates {
            $0.sessionStartPolicy.sessionBecameUnavailable()
        }
    }

    private func updateGates(_ mutation: @escaping (AppfslyerManager) -> Void) {
        let work = { [weak self] in
            guard let self else { return }
            mutation(self)
            self.startSessionIfReady()
        }

        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    private func startSessionIfReady() {
        guard isATTResolved, isUserIDReady,
              sessionStartPolicy.claimStart() else {
            return
        }
        applySharingFilter()

        // Taken before the call: a late completion must not get the number of a newer start.
        let attempt = sessionTally.beginStart(at: Date())
        AppsFlyerLib.shared().start { [weak self] _, error in
            self?.handleStartCompletion(error,
                                        attempt: attempt.number,
                                        secondsSincePreviousAttempt: attempt.secondsSincePreviousAttempt)
        }
    }

    /// `nil` clears the filter, `["all"]` covers every current and future partner.
    private func applySharingFilter() {
        AppsFlyerLib.shared().setSharingFilterForPartners(isAdPartnersDataSharingEnabled ? nil : ["all"])
    }

    /*
     Diagnostics only. A completion is not final for the session and may belong to an earlier
     foreground cycle, so it never touches the start permission or the conversion result.
     */
    private func handleStartCompletion(_ error: Error?,
                                       attempt number: Int,
                                       secondsSincePreviousAttempt: TimeInterval?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.handleStartCompletion(error,
                                            attempt: number,
                                            secondsSincePreviousAttempt: secondsSincePreviousAttempt)
            }
            return
        }

        sessionTally.finishStart(succeeded: error == nil)
        guard let error else {
            didEverStartSuccessfully = true
            return
        }

        let attempt = AppsFlyerStartAttempt(number: number,
                                            secondsSincePreviousAttempt: secondsSincePreviousAttempt,
                                            error: error)
        delegate?.appsflyerSessionStartAttemptFailed(error, attempt: attempt)
        // Classified before the token is consumed: a rate limited start is expected and must
        // not use up the one report per install.
        guard attempt.isRateLimited == false else {
            return
        }
        delegate?.appsflyerSessionStartFailed(error,
                                              shouldReport: consumeStartFailureReport())
    }

    private func handleConversionResult(_ result: ConversionResult) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.handleConversionResult(result)
            }
            return
        }

        switch result {
        case .success(let conversionInfo):
            deeplinkError = nil
            didDeliverConversionData = true
            let deepLinkInfo = parseDeepLink(conversionInfo)
            deeplinkResult = deepLinkInfo
            delegate?.handledDeeplink(deepLinkInfo)
            delegate?.coreConfiguration(didReceive: conversionInfo)
        case .failure(let error):
            deeplinkError = error
            delegate?.coreConfiguration(handleDeeplinkError: error)
        }
    }

    /// One shot token: `true` at most once per install, and never once a session has started.
    private func consumeStartFailureReport() -> Bool {
        guard didEverStartSuccessfully == false, didReportStartFailure == false else {
            return false
        }
        didReportStartFailure = true
        return true
    }

    private func parseDeepLink(_ conversionInfo: [AnyHashable : Any]) -> [String: String] {
        var appsFlyerProperties = [String: String]()

        let parsingKeys = [
            "media_source": "network",
            "campaign": "campaignName",
            "af_adset": "adGroupName",
            "af_ad": "ad",
            "deep_link_value": "deep_link_value",
            "af_dp": "deep_link_value"
        ]

        for key in conversionInfo.keys {
            if let conversionKey = key as? String, let conversionValue = conversionInfo[key] as? String {
                let keyToSave: String
                if parsingKeys.keys.contains(conversionKey), let newKey = parsingKeys[conversionKey] {
                    keyToSave = newKey
                } else {
                    keyToSave = conversionKey
                }
                appsFlyerProperties[keyToSave] = conversionValue
            }
        }

        return appsFlyerProperties
    }
}

extension AppfslyerManager: AppfslyerManagerProtocol {
    public var appsflyerID: String {
        AppsFlyerLib.shared().getAppsFlyerUID()
    }

    /// Main thread only: the tally behind it is written on main.
    public var appsflyerSession: AppsFlyerSessionState {
        sessionTally.state
    }

    public var customerUserID: String? {
        get {
            return AppsFlyerLib.shared().customerUserID
        }
        set {
            AppsFlyerLib.shared().customerUserID = newValue
        }
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                                   restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AppsFlyerLib.shared().registerUninstall(deviceToken)
    }

    public func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] ) {
        AppsFlyerLib.shared().handleOpen(url, options: options)
    }

    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AppsFlyerLib.shared().handlePushNotification(userInfo)
    }

    public func startAppsflyer() {
        updateGates { $0.isUserIDReady = true }
    }

    public func handleATTResolved() {
        updateGates { $0.isATTResolved = true }
    }

    public func setAdPartnersDataSharingEnabled(_ isEnabled: Bool) {
        updateGates {
            $0.isAdPartnersDataSharingEnabled = isEnabled
            $0.applySharingFilter()
        }
    }

    public func logTrialPurchase() {
        AppsFlyerLib.shared().logEvent(AFEventStartTrial, withValues: [:])
    }
}

extension AppfslyerManager: AppsFlyerLibDelegate {
    public func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        handleConversionResult(.success(conversionInfo))
    }

    public func onConversionDataFail(_ error: Error) {
        handleConversionResult(.failure(error))
    }

    // Kept for API compatibility; removal tracked separately.
    @available(*, deprecated, message: "AppsFlyer 7 removed this delegate callback; use conversion-data callbacks instead.")
    public func onAppOpenAttributionFailure(_ error: Error) {
        handleConversionResult(.failure(error))
    }
}
