import UIKit
import AppsFlyerLib

public class AppfslyerManager: NSObject {
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
    public var sessionStatus: String {
        session.value
    }

    private let deepLinkResultUDKey = "coreintegrations_appsflyer_deeplinkResult"
    private var startGate = AppsFlyerStartGate()
    private var session = AppsFlyerSessionStatus()
    private var isAdPartnersDataSharingEnabled = true

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

        // Launch options go in before the ready listener, so a cold start Universal Link is resolved first.
        AppsFlyerLib.shared().handleLaunchOptions(launchOptions)
        AppsFlyerLib.shared().registerSessionReadyListener { [weak self] in
            self?.updateGate { $0.isSessionReady = true }
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
        updateGate { $0.enteredBackground() }
    }

    private static func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    private func updateGate(_ change: @escaping (inout AppsFlyerStartGate) -> Void) {
        AppfslyerManager.onMain { [weak self] in
            guard let self else { return }
            change(&self.startGate)
            self.startSessionIfAllowed()
        }
    }

    private func startSessionIfAllowed() {
        guard startGate.claimStart(hasCustomerUserID: AppsFlyerLib.shared().customerUserID != nil) else {
            return
        }
        applySharingFilter()
        session.startBegan()
        AppsFlyerLib.shared().start { [weak self] _, error in
            AppfslyerManager.onMain { [weak self] in
                self?.session.startFinished(error: error)
            }
        }
    }

    /// `nil` clears the filter, `["all"]` covers every current and future partner.
    private func applySharingFilter() {
        AppsFlyerLib.shared().setSharingFilterForPartners(isAdPartnersDataSharingEnabled ? nil : ["all"])
    }

    private func handleConversion(_ result: Result<[AnyHashable: Any], Error>) {
        AppfslyerManager.onMain { [weak self] in
            guard let self else { return }
            switch result {
            case .success(let conversionInfo):
                self.deeplinkError = nil
                let deepLinkInfo = self.parseDeepLink(conversionInfo)
                self.deeplinkResult = deepLinkInfo
                self.delegate?.handledDeeplink(deepLinkInfo)
                self.delegate?.coreConfiguration(didReceive: conversionInfo)
            case .failure(let error):
                self.deeplinkError = error
                self.delegate?.coreConfiguration(handleDeeplinkError: error)
            }
        }
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

    public var customerUserID: String? {
        get {
            return AppsFlyerLib.shared().customerUserID
        }
        set {
            AppsFlyerLib.shared().customerUserID = newValue
            updateGate { _ in }
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

    public func handleATTResolved() {
        updateGate { $0.isATTResolved = true }
    }

    public func setAdPartnersDataSharingEnabled(_ isEnabled: Bool) {
        AppfslyerManager.onMain { [weak self] in
            self?.isAdPartnersDataSharingEnabled = isEnabled
            self?.applySharingFilter()
        }
    }

    public func logTrialPurchase() {
        AppsFlyerLib.shared().logEvent(AFEventStartTrial, withValues: [:])
    }
}

extension AppfslyerManager: AppsFlyerLibDelegate {
    public func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        handleConversion(.success(conversionInfo))
    }

    public func onConversionDataFail(_ error: Error) {
        handleConversion(.failure(error))
    }
}
