
import UIKit
#if !COCOAPODS
import AppsflyerIntegration
import FacebookIntegration
import AttributionServerIntegration
import PurchasesIntegration
import AnalyticsIntegration
import RemoteTestingIntegration
import SentryIntegration
import FirebaseIntegration
#endif
import AppTrackingTransparency
import Foundation
import StoreKit

// MARK: Configuration
public class CoreManager {
    public static var shared: CoreManagerProtocol = internalShared
    static var internalShared = CoreManager()
    
    public static var uniqueUserID: String? {
        return AttributionServerManager.shared.uniqueUserID
    }
    
    public static var sentry:PublicSentryManagerProtocol {
        return SentryManager.shared
    }
    
    public var userInfo: UserInfo {
        get {
            guard let userInfoData = UserDefaults.standard.data(forKey: "coreintegrations.userAttrInfo"),
                  let userInfo = try? JSONDecoder().decode(UserInfo.self, from: userInfoData) else {
                return UserInfo(userSource: .organic, attrInfo: [:])
            }
            
            return userInfo
        }
        set {
            let userData = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.set(userData, forKey: "coreintegrations.userAttrInfo")
        }
    }
    
    var attAnswered: Bool = false
    var isConfigured: Bool = false
    var handledNoInternetAlert: Bool = false
    
    var configuration: CoreConfigurationProtocol?
    var appsflyerManager: AppfslyerManagerProtocol?
    var facebookManager: FacebookManagerProtocol?
    var purchaseManager: PurchasesManagerProtocol?
    
    var remoteConfigManager: RemoteConfigManager?
    var analyticsManager: AnalyticsManager?
    var sentryManager: InternalSentryManagerProtocol = SentryManager.shared
    var firebaseManager: FirebaseManager = FirebaseManager()
    
    var delegate: CoreManagerDelegate?
        
    var idConfigured = false
    
    func configureAll(configuration: CoreConfigurationProtocol) {
        func verifyTestEnvironment(envVariables: [String: String]) -> Bool {
            return envVariables["xctest_skip_config"] != nil
        }
        
        func handleTestEnvironment(envVariables: [String: String]) -> CoreManagerResult{
            let xc_network = environmentVariables["xctest_network"] ?? "organic"
            let xc_activePaywallName = environmentVariables["xctest_activePaywallName"] ?? "none"
            
            if let xc_screen_style_full = environmentVariables["xc_screen_style_full"] {
                let screen_style_full = configuration.remoteConfigDataSource.allConfigs.first(where: {$0.key == "subscription_screen_style_full"})
                screen_style_full?.updateValue(xc_screen_style_full)
            }
            
            if let xc_screen_style_h = environmentVariables["xc_screen_style_h"] {
                let hardPaywall = configuration.remoteConfigDataSource.allConfigs.first(where: {$0.key == "subscription_screen_style_h"})
                hardPaywall?.updateValue(xc_screen_style_h)
            }
            
            //            let data = CoreManagerResultData(userSource: CoreUserSource(rawValue: xc_network), activePaywallName: xc_activePaywallName, isActivePaywallDefault: true, paywallsBySource: [CoreUserSource(rawValue: xc_network) : xc_activePaywallName])
            let result = CoreManagerResult.finished
            
            purchaseManager = PurchasesManager.shared
            purchaseManager?.initialize(allIdentifiers: configuration.paywallDataSource.allPurchaseIDs, proIdentifiers: configuration.paywallDataSource.allProPurchaseIDs)
            return result
        }
        
        func configureServices(configuration: CoreConfigurationProtocol) {
            if let sentryDataSource = configuration.sentryConfigDataSource {
                let sentryConfig = SentryConfigData(dsn: sentryDataSource.dsn,
                                                    debug: sentryDataSource.debug,
                                                    tracesSampleRate: sentryDataSource.tracesSampleRate,
                                                    profilesSampleRate: sentryDataSource.profilesSampleRate,
                                                    shouldCaptureHttpRequests: sentryDataSource.shouldCaptureHttpRequests,
                                                    httpCodesRange: sentryDataSource.httpCodesRange,
                                                    handledDomains: sentryDataSource.handledDomains)
                sentryManager.configure(sentryConfig)
            }
            
            analyticsManager = AnalyticsManager.shared
            
            let amplitudeCustomURL = configuration.amplitudeDataSource.customServerURL
            
            analyticsManager?.configure(appKey: configuration.appSettings.amplitudeSecret,
                                        cnConfig: AppEnvironment.isChina,
                                        customURL: amplitudeCustomURL)
            
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
            
            appsflyerManager = AppfslyerManager(config: configuration.appsflyerConfig)
            appsflyerManager?.delegate = self
            
            facebookManager = FacebookManager()
            
            purchaseManager = PurchasesManager.shared
            
            let attributionToken = configuration.appSettings.attributionServerSecret
            let facebookData = AttributionFacebookModel(fbUserId: facebookManager?.userID ?? "",
                                                        fbUserData: facebookManager?.userData ?? "",
                                                        fbAnonId: facebookManager?.anonUserID ?? "")
            let appsflyerToken = appsflyerManager?.appsflyerID
            
            purchaseManager?.initialize(allIdentifiers: configuration.paywallDataSource.allPurchaseIDs, proIdentifiers: configuration.paywallDataSource.allProPurchaseIDs)
            
            remoteConfigManager = CoreRemoteConfigManager(deploymentKey: configuration.appSettings.amplitudeDeploymentKey)
            
            let installPath = "/install-application"
            let purchasePath = "/subscribe"
            let installURLPath = configuration.attributionServerDataSource.installPath
            let purchaseURLPath = configuration.attributionServerDataSource.purchasePath
            
            let attributionConfiguration = AttributionConfigData(authToken: attributionToken,
                                                                 installServerURLPath: installURLPath,
                                                                 purchaseServerURLPath: purchaseURLPath,
                                                                 installPath: installPath,
                                                                 purchasePath: purchasePath,
                                                                 appsflyerID: appsflyerToken,
                                                                 facebookData: facebookData)
            
            AttributionServerManager.shared.configure(config: attributionConfiguration)
        }
        
        guard isConfigured == false else {
            return
        }
        isConfigured = true
        
        let environmentVariables = ProcessInfo.processInfo.environment
        if verifyTestEnvironment(envVariables: environmentVariables) {
            let result = handleTestEnvironment(envVariables: environmentVariables)
            self.delegate?.coreConfigurationFinished(result: result)
            return
        }
        
        self.configuration = configuration
        
        configureServices(configuration: configuration)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
        signForConfigurationFinish()
        
        signForAttributionInstall()
        signForAttributionFinish()
    }
    
    @objc public func applicationDidBecomeActive() {
        configureID()
        
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
            firebaseManager.configure(id: id)
            sentryManager.setUserID(id)
            self.analyticsManager?.setUserID(id)
            remoteConfigManager?.configure(configuration?.remoteConfigDataSource.allConfigs ?? []) { [weak self] in
                InternalConfigurationEvent.remoteConfigLoaded.markAsCompleted(error: self?.remoteConfigManager?.remoteError)
            }
        }
    }
    
    func requestATT() {
        let attStatus = ATTrackingManager.trackingAuthorizationStatus
        guard attStatus == .notDetermined else {
            self.sendATTProperty(answer: attStatus == .authorized)
            
            guard attAnswered == false else { return }
            attAnswered = true
            
            handleATTAnswered(attStatus)
            return
        }
        
        /*
         This stupid thing is made to be sure, that we'll handle ATT anyways, 100%
         And it looks like that apple has a bug, at least in sandbox, when ATT == .notDetermined
         but ATT alert for some reason not showing up, so it keeps unhandled and configuration never ends also
         The only problem this solution brings - if user really don't unswer ATT for more than 5 seconds -
         then we would think he didn't answer and the result would be false, even if he would answer true
         in more than 3 seconds
         */
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
            guard self?.attAnswered == false else { return }
            self?.attAnswered = true
            
            self?.sendAttEvent(answer: false)
            let status = ATTrackingManager.trackingAuthorizationStatus
            self?.handleATTAnswered(status, error: NSError(domain: "coreintegrations.att.timeout", code: 6456))
        }
        
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            guard self?.attAnswered == false else { return }
            self?.attAnswered = true
            
            self?.sendAttEvent(answer: status == .authorized)
            self?.handleATTAnswered(status)
        }
    }
    
    func handleATTAnswered(_ status: ATTrackingManager.AuthorizationStatus, error: Error? = nil) {
        AppConfigurationManager.shared?.startTimoutTimer()
        InternalConfigurationEvent.attConcentGiven.markAsCompleted(error: error)
        facebookManager?.configureATT(isAuthorized: status == .authorized)
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
        
        let installURLPath = InternalRemoteConfig.install_server_path.value
        let purchaseURLPath = InternalRemoteConfig.purchase_server_path.value
        if installURLPath != "" && purchaseURLPath != "" {
            let attributionConfiguration = AttributionConfigURLs(installServerURLPath: installURLPath,
                                                                 purchaseServerURLPath: purchaseURLPath,
                                                                 installPath: installPath,
                                                                 purchasePath: purchasePath)
            
            AttributionServerManager.shared.configureURLs(config: attributionConfiguration)
        } else {
            if let serverDataSource = configuration?.attributionServerDataSource {
                let installURLPath = serverDataSource.installPath
                let purchaseURLPath = serverDataSource.purchasePath
                
                let attributionConfiguration = AttributionConfigURLs(installServerURLPath: installURLPath,
                                                                     purchaseServerURLPath: purchaseURLPath,
                                                                     installPath: installPath,
                                                                     purchasePath: purchasePath)
                
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
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        
        let isInternetError = checkIsNoInternetError()
        
        if isInternetError && checkIsNoInternetHandledOrIgnored() == false && isUpdated == false {
            AppConfigurationManager.shared?.reset()
            attAnswered = false
            signForAttributionInstall()
            signForAttributionFinish()
            signForConfigurationFinish()
            delegate?.coreConfigurationFinished(result: .noInternet)
            return
        }
        
        let result = getAttributionResult()
        
        var attributionDict: [String: String] = ["network": result.network.rawValue]
        if result.userAttribution.isEmpty == false {
            attributionDict += result.userAttribution
        }
        
        let currentUserInfo = userInfo
        
        if currentUserInfo.userSource != result.network {
            userInfo = UserInfo(userSource: result.network, attrInfo: result.userAttribution)
            if isUpdated {
                sendUserAttributionUpdate(userAttribution: attributionDict, status: configurationManager.statusForAnalytics)
            } else {
                sendUserAttribution(userAttribution: attributionDict, status: configurationManager.statusForAnalytics)
            }
            
            remoteConfigManager?.updateRemoteConfig(attributionDict) { [weak self] in
                InternalConfigurationEvent.remoteConfigUpdated.markAsCompleted(error: self?.remoteConfigManager?.remoteError)
            }
        }
    }
    
    func getAttributionResult() -> (network: CoreUserSource, userAttribution: [String: String]) {
        let deepLinkResult = self.appsflyerManager?.deeplinkResult ?? [:]
        let asaResult = AttributionServerManager.shared.installResultData
        
        let isIPAT = asaResult?.isIPAT ?? false
        let isASA = (asaResult?.asaAttribution["campaignName"] as? String != nil) ||
        (asaResult?.asaAttribution["campaign_name"] as? String != nil)
        
        var networkSource: CoreUserSource = .organic
        
        var userAttribution = [String: String]()
        if let networkValue = deepLinkResult["network"] {
            networkSource = .other(networkValue)
            userAttribution = deepLinkResult
        } else if isIPAT {
            networkSource = .ipat
        } else if isASA {
            networkSource = .asa
            userAttribution = asaResult?.asaAttribution ?? [:]
        }
        
        return (networkSource, userAttribution)
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
        self.delegate?.coreConfigurationFinished(result: result)
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
        let afError = appsflyerManager?.deeplinkError
        let remoteError = remoteConfigManager?.remoteError

        return attrError != nil && afError != nil && remoteError != nil
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
}
