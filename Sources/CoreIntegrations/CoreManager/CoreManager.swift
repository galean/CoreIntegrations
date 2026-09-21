
import UIKit
#if !COCOAPODS
import AppsflyerIntegration
import FacebookIntegration
import AttributionServerIntegration
import PurchasesIntegration
import AnalyticsIntegration
import RemoteTestingIntegration
import SentryIntegration
import AttestationIntegration
import FirebaseIntegration
import LoggingIntegration
#endif
import Foundation
import StoreKit

// MARK: Configuration
public class CoreManager {
    public static var shared: CoreManagerProtocol = internalShared
    static var internalShared = CoreManager()
        
    public static var uniqueUserID: String? {
        return AttributionServerManager.shared.uniqueUserID
    }
    
    public var fcmToken: String? {
        return firebaseManager.fcmToken
    }
    
    public static var sentry:PublicSentryManagerProtocol {
        return SentryManager.shared
    }
    
    public var userInfo: UserInfo? {
        get {
            guard let userInfoData = UserDefaults.standard.data(forKey: "coreintegrations.userAttrInfo"),
                  let userInfo = try? JSONDecoder().decode(UserInfo.self, from: userInfoData) else {
                return nil
            }
            
            return userInfo
        }
        set {
            guard newValue != nil else {
                UserDefaults.standard.removeObject(forKey: "coreintegrations.userAttrInfo")
                return
            }
            
            let userData = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.set(userData, forKey: "coreintegrations.userAttrInfo")
        }
    }
    
    lazy var attResolutionCoordinator = makeATTResolutionCoordinator()
    var appsflyerConfigurationOutcomePolicy = AppsFlyerConfigurationOutcomePolicy()
    var isConfigured: Bool = false
    
    var configuration: CoreConfigurationProtocol?
    var isAdPartnersDataSharingEnabled: Bool = true
    var appsflyerManager: AppfslyerManagerProtocol?
    var facebookManager: FacebookManagerProtocol?
    var purchaseManager: PurchasesManagerProtocol?
    
    var remoteConfigManager: RemoteConfigManager?
    var analyticsManager: AnalyticsManager?
    var sentryManager: InternalSentryManagerProtocol = SentryManager.shared
    
    var firebaseManager = FirebaseConfigurationStateMachine()

    var delegate: CoreManagerDelegate?
        
    var idConfigured = false
    
    var handledNoInternetAlert: Bool = false
    var shouldReconfigure = false
    
    var networkMonitor = NetworkManager()
    
    @MainActor
    func configureAll(configuration: CoreConfigurationProtocol,
                      launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
        func verifyTestEnvironment(envVariables: [String: String]) -> Bool {
            return envVariables["xctest_skip_config"] != nil
        }
        
        func handleTestEnvironment(envVariables: [String: String]) -> CoreManagerResult{
            purchaseManager = PurchasesManager.shared
            purchaseManager?.initialize(allIdentifiers: configuration.paywallDataSource.allPurchaseIDs, proIdentifiers: configuration.paywallDataSource.allProPurchaseIDs)
            
            if let _ = environmentVariables["xctest_remote_config_enabled"] {
                analyticsManager = AnalyticsManager.shared
                
                let amplitudeDataSource = configuration.amplitudeDataSource
                analyticsManager?.configure(
                    data: .init(
                        appKey: configuration.appSettings.amplitudeSecret,
                        cnConfig: AppEnvironment.isChina,
                        customURL: amplitudeDataSource.customServerURL,
                        plugins: amplitudeDataSource.plugins,
                        sessionReplayConfig: .init(
                            startOnLaunch: amplitudeDataSource.sessionReplayStartOnLaunch,
                            sampleRate: amplitudeDataSource.sessionReplaySampleRate,
                            enableRemoteConfig: amplitudeDataSource.sessionReplayEnableRemoteConfig
                        )
                    )
                )
                
                remoteConfigManager = CoreRemoteConfigManager(deploymentKey: configuration.appSettings.amplitudeDeploymentKey,
                                                              userInfo: [InternalUserProperty.app_environment.key: AppEnvironment.current.rawValue])
            }
            if let xc_screen_style_full = environmentVariables["xc_screen_style_full"] {
                let screen_style_full = configuration.remoteConfigDataSource.allConfigs.first(where: {$0.key == "subscription_screen_style_full"})
                screen_style_full?.updateValue(xc_screen_style_full)
            }
            
            if let xc_screen_style_h = environmentVariables["xc_screen_style_h"] {
                let hardPaywall = configuration.remoteConfigDataSource.allConfigs.first(where: {$0.key == "subscription_screen_style_h"})
                hardPaywall?.updateValue(xc_screen_style_h)
            }
            
            if let xc_ab_paywall = environmentVariables["xctest_activePaywallName"] {
                let ab_paywall = configuration.remoteConfigDataSource.allConfigs.first(where: {$0.key == "ab_paywall"})
                ab_paywall?.updateValue(xc_ab_paywall)
            }
            
            let result = CoreManagerResult.finished
            
            return result
        }
        
        func configureServices(configuration: CoreConfigurationProtocol) {
            isAdPartnersDataSharingEnabled = configuration.isAdPartnersDataSharingEnabled
            
            if let sentryDataSource = configuration.sentryConfigDataSource {
                let sentryConfig = SentryConfigData(dsn: sentryDataSource.dsn,
                                                    debug: sentryDataSource.debug,
                                                    enableLogs: sentryDataSource.enableLogs,
                                                    tracesSampleRate: sentryDataSource.tracesSampleRate,
                                                    shouldCaptureHttpRequests: sentryDataSource.shouldCaptureHttpRequests,
                                                    httpCodesRange: sentryDataSource.httpCodesRange,
                                                    handledDomains: sentryDataSource.handledDomains,
                                                    swizzleClassNameExcludes: sentryDataSource.swizzleClassNameExcludes)
                sentryManager.configure(sentryConfig)
            }
            
            analyticsManager = AnalyticsManager.shared
            
            firebaseManager.setAdPartnersDataSharingEnabled(isAdPartnersDataSharingEnabled)
            
            if configuration.hasCustomFirebaseConfiguration {
                firebaseManager.handle(event: FirebaseConfigurationStateMachine.Event.waitForExternalConfiguration)
            } 
            
            let amplitudeDataSource = configuration.amplitudeDataSource
            analyticsManager?.configure(
                data: .init(
                    appKey: configuration.appSettings.amplitudeSecret,
                    cnConfig: AppEnvironment.isChina,
                    customURL: amplitudeDataSource.customServerURL,
                    plugins: amplitudeDataSource.plugins,
                    sessionReplayConfig: .init(
                        startOnLaunch: amplitudeDataSource.sessionReplayStartOnLaunch,
                        sampleRate: amplitudeDataSource.sessionReplaySampleRate,
                        enableRemoteConfig: amplitudeDataSource.sessionReplayEnableRemoteConfig
                    )
                )
            )
            
            sendStoreCountryUserProperty()
            configuration.appSettings.launchCount += 1
            if configuration.appSettings.isFirstLaunch {
                sendAppEnvironmentProperty()
                sendFirstLaunchEvent()
            }
            
            let allConfigurationEvents: [any ConfigurationEvent] = InternalConfigurationEvent.allCases + (configuration.initialConfigurationDataSource?.allEvents ?? [])
            AppConfigurationManager.shared = AppConfigurationManager(allConfigurationEvents: allConfigurationEvents,
                                                                     isFirstStart: configuration.appSettings.isFirstLaunch,
                                                                     timeout: configuration.configurationTimeout)
            
            appsflyerManager = AppfslyerManager(config: configuration.appsflyerConfig,
                                                launchOptions: launchOptions)
            appsflyerManager?.delegate = self
            appsflyerManager?.setAdPartnersDataSharingEnabled(isAdPartnersDataSharingEnabled)
            
            if configuration.isFacebookEnabled {
                facebookManager = FacebookManager()
            }
            
            purchaseManager = PurchasesManager.shared
            
            let attributionToken = configuration.appSettings.attributionServerSecret
            let facebookData = AttributionFacebookModel(fbUserId: facebookManager?.userID ?? "",
                                                        fbUserData: facebookManager?.userData ?? "",
                                                        fbAnonId: facebookManager?.anonUserID ?? "")
            let appsflyerToken = appsflyerManager?.appsflyerID
            
            purchaseManager?.initialize(allIdentifiers: configuration.paywallDataSource.allPurchaseIDs, proIdentifiers: configuration.paywallDataSource.allProPurchaseIDs)
            
            remoteConfigManager = CoreRemoteConfigManager(deploymentKey: configuration.appSettings.amplitudeDeploymentKey,
                                                          userInfo: [InternalUserProperty.app_environment.key: AppEnvironment.current.rawValue],
                                                          customServerURL: configuration.customAmplitudeServer)
            
            let installPath = "/install-application"
            let purchasePath = "/subscribe"
			let appTransactionPath = "/app-transaction"
            let tokensPath = "/tokens"
            let externalAuthPath = "/external-authorization"
            let installURLPath = configuration.attributionServerDataSource.installPath
            let purchaseURLPath = configuration.attributionServerDataSource.purchasePath
            let externalAuthURLPath = configuration.attributionServerDataSource.externalAuthPath

            let attributionConfiguration = AttributionConfigData(authToken: attributionToken,
                                                                 installServerURLPath: installURLPath,
                                                                 purchaseServerURLPath: purchaseURLPath,
                                                                 externalAuthServerURLPath: externalAuthURLPath,
                                                                 installPath: installPath,
                                                                 appTransactionPath: appTransactionPath,
                                                                 externalAuthPath: externalAuthPath,
                                                                 purchasePath: purchasePath,
                                                                 appsflyerID: appsflyerToken,
                                                                 appEnvironment: AppEnvironment.current.rawValue,
                                                                 facebookData: facebookData,
                                                                 tokensPath: tokensPath,
                                                                 hasExternalAuth: configuration.hasExternalAuthorization)
            
            AttributionServerManager.shared.configure(config: attributionConfiguration)
        }
        
        guard isConfigured == false else {
            return
        }
        isConfigured = true
        DebugLogger.isEnabled = configuration.isDebugLoggingEnabled
        self.configuration = configuration
        
        let environmentVariables = ProcessInfo.processInfo.environment
        if verifyTestEnvironment(envVariables: environmentVariables) {
            if environmentVariables["xctest_remote_config_enabled"] != nil {
                let result = handleTestEnvironment(envVariables: environmentVariables)
                
                remoteConfigManager?.configure(configuration.remoteConfigDataSource.allConfigs) { [weak self] in
                    self?.delegate?.coreConfigurationFinished(result: result)
                }
            } else {
                let result = handleTestEnvironment(envVariables: environmentVariables)
                self.delegate?.coreConfigurationFinished(result: result)
            }
            return
        }
        
        configureServices(configuration: configuration)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleFCMTokenUpdate),
                                               name: NSNotification.Name("FCMTokenUpdated"),
                                               object: nil)
        
        signForConfigurationFinish()
        signForAttributionInstall()
        signForAttributionFinish()
    }
    
    func reconfigure() {
        resetConfigurationGeneration()
        signForAttributionInstall()
        signForAttributionFinish()
        signForConfigurationFinish()
        
        remoteConfigManager?.updateRemoteConfig([:]) { [ weak self] in
            self?.remoteConfigManager?.configure(self?.configuration?.remoteConfigDataSource.allConfigs ?? []) { [weak self] in
                InternalConfigurationEvent.remoteConfigLoaded.markAsCompleted(error: self?.remoteConfigManager?.remoteError)
            }
        }
    }

    private func resetConfigurationGeneration() {
        AppConfigurationManager.shared?.reset()
        appsflyerConfigurationOutcomePolicy.reset()
    }
    
    func internalHanleAuthID(_ authID: String?) {
        guard configuration?.hasExternalAuthorization != false else {
            assertionFailure()
            return
        }
        
        if let authID, authID != "" {
            analyticsManager?.setUserID(authID)
        } else {
            analyticsManager?.clearUserID()
        }
        
        guard let authID else {
            return
        }
        AttributionServerManager.shared.sendExternalAuthorization(externalAuthID: authID)
    }
    
    @MainActor
    @objc public func applicationDidBecomeActive() {
        configureID()
        
        if shouldReconfigure && handledNoInternetAlert {
            shouldReconfigure = false
            reconfigure()
        }
        
        if appsflyerManager?.customerUserID != nil {
            appsflyerManager?.startAppsflyer()
        } else {
            sentryManager.log(NSError(domain: "coreintegrations.appsflyer.noCustomerUserID", code: 1001))
        }
        
        if configuration?.useDefaultATTRequest == true {
            requestATT()
        }
        
        Task {
            await purchaseManager?.updateProductStatus()
        }
    }
    
    @MainActor
    private func configureID() {
        let savedIDFV = AttributionServerManager.shared.installResultData?.idfv
        let uuid = AttributionServerManager.shared.savedUserUUID
        
        let id: String?
        if savedIDFV != nil {
            id = AttributionServerManager.shared.uniqueUserID
        } else {
            id = uuid ?? AttributionServerManager.shared.uniqueUserID
        }
        if let id, id != "" {
            guard !idConfigured else {
                return
            }
            idConfigured = true
            appsflyerManager?.customerUserID = id
            purchaseManager?.setUserID(id)
            facebookManager?.userID = id
            firebaseManager.handle(event: FirebaseConfigurationStateMachine.Event.configureInternallyIfNeeded)
            firebaseManager.handle(event: FirebaseConfigurationStateMachine.Event.handleIDSetup(id: id))
            sentryManager.setUserID(id)
            sendFCMTokenIfAvailable(userId:id)
            if configuration?.hasExternalAuthorization != true {
                analyticsManager?.setUserID(id)
            }
            self.delegate?.coreInitialConfigurationFinished()
            remoteConfigManager?.configure(configuration?.remoteConfigDataSource.allConfigs ?? []) { [weak self] in
                InternalConfigurationEvent.remoteConfigLoaded.markAsCompleted(error: self?.remoteConfigManager?.remoteError)
                self?.delegate?.coreInitialRemoteConfigurationFinished()
            }
            
        }
    }
    
    func handleExternalFirebaseConfigurationFinished() {
        firebaseManager.handle(event: FirebaseConfigurationStateMachine.Event.handleExternalConfigurationFinished)
    }
    
}

// MARK: Attribution Start
extension CoreManager {
    func signForAttributionInstall() {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
    
        configurationManager.signForAttAndConfigLoaded { [weak self] in
            self?.handleAttributionInstall()
        }
    }
    
    func handleAttributionInstall() {
        let installPath = "/install-application"
        let purchasePath = "/subscribe"
        let tokensPath = "/tokens"
        let externalAuthPath = "/external-authorization"
		let appTransactionPath = "/app-transaction"
        let installURLPath = (InternalRemoteConfig.install_server_path.internalPayload?.first?.value as? String) ?? ""
        let purchaseURLPath = (InternalRemoteConfig.purchase_server_path.internalPayload?.first?.value as? String) ?? ""
        let externalAuthURLPath = InternalRemoteConfig.external_auth_server_path.internalValue

        if installURLPath != "" && purchaseURLPath != "" {
            let attributionConfiguration = AttributionConfigURLs(installServerURLPath: installURLPath,
                                                                 purchaseServerURLPath: purchaseURLPath,
                                                                 externalAuthServerURLPath: externalAuthURLPath,
                                                                 appTransactionPath: appTransactionPath,
                                                                 installPath: installPath,
                                                                 purchasePath: purchasePath,
                                                                 externalAuthPath: externalAuthPath,
                                                                 tokensPath: tokensPath)
            
            AttributionServerManager.shared.configureURLs(config: attributionConfiguration)
        } else {
            if let serverDataSource = configuration?.attributionServerDataSource {
                let installURLPath = serverDataSource.installPath
                let purchaseURLPath = serverDataSource.purchasePath

                let attributionConfiguration = AttributionConfigURLs(installServerURLPath: installURLPath,
                                                                     purchaseServerURLPath: purchaseURLPath,
                                                                     externalAuthServerURLPath: externalAuthURLPath,
                                                                     installPath: installPath,
                                                                     purchasePath: purchasePath,
                                                                     externalAuthPath: externalAuthPath,
                                                                     tokensPath: tokensPath)
                
                AttributionServerManager.shared.configureURLs(config: attributionConfiguration)
            } else {
                assertionFailure()
            }
        }
        
        AttributionServerManager.shared.syncOnAppStart { result in
            self.handlePossibleAttributionUpdate()
            InternalConfigurationEvent.attributionServerHandled.markAsCompleted(error: AttributionServerManager.shared.installError)
        }
    }
}

// MARK: Attribution finished
extension CoreManager {
    func signForAttributionFinish() {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        
        configurationManager.signForAttributionFinished { [weak self] in
            self?.handleAttributionFinish(isUpdated: false)
        }
    }
    
    func handleAttributionFinish(isUpdated: Bool) {
        MainQueueExecutor.perform { [weak self] in
            self?.handleAttributionFinishOnMain(isUpdated: isUpdated)
        }
    }

    private func handleAttributionFinishOnMain(isUpdated: Bool) {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        
        let isInternetError = checkIsNoInternetError()
        
        if isInternetError && checkIsNoInternetHandledOrIgnored() == false && isUpdated == false {
            shouldReconfigure = true
            resetConfigurationGeneration()
            delegate?.coreConfigurationFinished(result: .noInternet)
            return
        }
        
        let result = getAttributionResult()
        
        var attributionDict: [String: String] = ["network": result.network.rawValue]
        if let ipat = result.isIPAT {
            attributionDict["ipat"] = "\(ipat)"
        }
        if result.userAttribution.isEmpty == false {
            attributionDict += result.userAttribution
        }
        
        let currentUserInfo = userInfo
        
        if currentUserInfo == nil || currentUserInfo?.userSource != result.network || currentUserInfo?.isIPAT != result.isIPAT {
            userInfo = UserInfo(userSource: result.network, isIPAT: result.isIPAT, attrInfo: result.userAttribution)
            if result.network == .organic {
                if let ipat = result.isIPAT, currentUserInfo?.isIPAT != result.isIPAT {
                    if isUpdated {
                        sendUserAttributionUpdate(userAttribution: ["ipat": "\(ipat)"])
                    } else {
                        sendUserAttribution(userAttribution: ["ipat": "\(ipat)"], status: configurationManager.statusForAnalytics)
                    }
                    
                    remoteConfigManager?.updateRemoteConfig(["ipat": "\(ipat)"]) { [weak self] in
                        InternalConfigurationEvent.remoteConfigUpdated.markAsCompleted(error: self?.remoteConfigManager?.remoteError)
                    }
                } else {
                    sendUserAttribution(userAttribution: [:], status: configurationManager.statusForAnalytics)
                    
                    remoteConfigManager?.updateRemoteConfig([:]) { [weak self] in
                        InternalConfigurationEvent.remoteConfigUpdated.markAsCompleted(error: self?.remoteConfigManager?.remoteError)
                    }
                }
            } else {
                if isUpdated {
                    sendUserAttributionUpdate(userAttribution: attributionDict)
                } else {
                    sendUserAttribution(userAttribution: attributionDict, status: configurationManager.statusForAnalytics)
                }
                
                remoteConfigManager?.updateRemoteConfig(attributionDict) { [weak self] in
                    InternalConfigurationEvent.remoteConfigUpdated.markAsCompleted(error: self?.remoteConfigManager?.remoteError)
                    if isUpdated {
                        self?.delegate?.coreConfigurationUpdated()
                    }
                }
            }
        } else {
            InternalConfigurationEvent.remoteConfigUpdated.markAsCompleted(error: remoteConfigManager?.remoteError)
        }
    }
    
    func getAttributionResult() -> (network: CoreUserSource, isIPAT: Bool?, userAttribution: [String: String]) {
        let deepLinkResult = self.appsflyerManager?.deeplinkResult ?? [:]
        let asaResult = AttributionServerManager.shared.installResultData
        
        let isIPAT = asaResult?.isIPAT
        let isASA = (asaResult?.asaAttribution["campaignName"] as? String != nil) ||
        (asaResult?.asaAttribution["campaign_name"] as? String != nil)
        
        var networkSource: CoreUserSource = .organic
        
        var userAttribution = [String: String]()
        if let networkValue = deepLinkResult["network"] {
            if networkValue == "Full_Access" {
                networkSource = .test_premium
            } else if networkValue.lowercased() == "tiktok_full_access" {
                networkSource = .tiktok_full_access
            } else {
                networkSource = .other(networkValue)
            }
            userAttribution = deepLinkResult
        } else if isASA {
            networkSource = .asa
            userAttribution = asaResult?.asaAttribution ?? [:]
        }
        
        return (networkSource, isIPAT, userAttribution)
    }
}

// MARK: Attrubution Update
extension CoreManager {
    func handlePossibleAttributionUpdate() {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        
        guard configurationManager.attributionFinishHandled else {
            return
        }
        
        handleAttributionFinish(isUpdated: true)
    }
}

// MARK: Configuration
extension CoreManager {
    func signForConfigurationFinish() {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        
        configurationManager.signForConfigurationEnd { [weak self] configurationResult in
            self?.handleConfigurationFinish(result: .finished)
        }
    }
    
    func handleConfigurationFinish(result: CoreManagerResult) {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        
        sendConfigurationFinished(status: configurationManager.statusForAnalytics)
        self.delegate?.coreConfigurationFinished(result: result)
        networkMonitor.stopMonitoring()
    }
}

// MARK: Support
extension CoreManager {
    func checkIsNoInternetHandledOrIgnored() -> Bool {
        guard AppEnvironment.isChina else {
            return true
        }
        
        guard configuration?.appSettings.isFirstLaunch == true else {
            return true
        }
        
        let noInternetCanBeShown = !handledNoInternetAlert
        guard noInternetCanBeShown else {
            return true
        }
        
        return false
    }
    
    func checkIsNoInternetError() -> Bool {
        let attrError = AttributionServerManager.shared.installError
        let remoteError = remoteConfigManager?.remoteError

        return attrError != nil && remoteError != nil
    }
}

// MARK: Purchases
extension CoreManager {
    func sendPurchaseToAttributionServer(_ details: PurchaseDetails) {
        let tlmamDetals = AttributionPurchaseModel(details)
        AttributionServerManager.shared.syncPurchase(data: tlmamDetals)
    }
    
    func sendPurchaseToFacebook(_ purchase: PurchaseDetails) {
        guard facebookManager != nil else {
            return
        }
        
        let isTrial = purchase.product.subscription?.introductoryOffer != nil
        let trialPrice = CGFloat(NSDecimalNumber(decimal: purchase.product.subscription?.introductoryOffer?.price ?? 0).floatValue)//introductoryPrice?.price.doubleValue ?? 0
        let price = CGFloat(NSDecimalNumber(decimal: purchase.product.price).floatValue)
        let currencyCode = purchase.product.priceFormatStyle.currencyCode
        let analData = FacebookPurchaseData(isTrial: isTrial,
                                            subcriptionID: purchase.product.id,
                                            trialPrice: trialPrice, price: price,
                                            currencyCode: currencyCode)
        self.facebookManager?.sendPurchaseAnalytics(analData)
    }
    
    func sendPurchaseToAppsflyer(_ purchase: PurchaseDetails) {
        guard appsflyerManager != nil else {
            return
        }
        
        let isTrial = purchase.product.subscription?.introductoryOffer != nil
        if isTrial {
            self.appsflyerManager?.logTrialPurchase()
        }
    }
    
    @objc private func handleFCMTokenUpdate(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let userId = userInfo["userId"] as? String {
                sendFCMTokenIfAvailable(userId:userId)
            }
        }
    }
    
    private func sendFCMTokenIfAvailable(userId: String) {
        guard let fcmToken = firebaseManager.fcmToken,
              let localization = configuration?.appLocalization else {
            return
        }
        
        AttributionServerManager.shared.checkAndSendSavedFCMToken(fcmToken: fcmToken, userId: userId, localization: localization) { result in
            DebugLogger.log("FCM token sent successfully - \(result)")
        }
        
        self.delegate?.coreConfiguration(fcmTokenUpdated: fcmToken)
    }
}
