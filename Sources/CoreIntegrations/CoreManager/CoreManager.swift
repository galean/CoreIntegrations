
import UIKit
#if !COCOAPODS
import AppsflyerIntegration
import FacebookIntegration
import AttributionServerIntegration
import PurchasesIntegration
import AnalyticsIntegration
import RemoteTestingIntegration
import SentryIntegration
#endif
import AppTrackingTransparency
import Foundation
import StoreKit

/*
    I think it would be good to split CoreManager into different manager parts - for default configuration, for additional configurations like analytics, test_distribution etc, and for purchases and purchases attribution part
 */
public class CoreManager {
    public static var shared: CoreManagerProtocol = internalShared
    static var internalShared = CoreManager()
    
    public static var uniqueUserID: String? {
        return AttributionServerManager.shared.uniqueUserID
    }
    
    public static var sentry:PublicSentryManagerProtocol {
        return SentryManager.shared
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
    
    var delegate: CoreManagerDelegate?
    
    var configurationResultManager = ConfigurationResultManager()
    
    let configurationEndQueue = DispatchQueue(label: "coreIntegrations.manager.endQueue")
    
    var idConfigured = false
    
    func configureAll(configuration: CoreConfigurationProtocol) {
        guard isConfigured == false else {
            return
        }
        isConfigured = true
        
        let environmentVariables = ProcessInfo.processInfo.environment
        if let _ = environmentVariables["xctest_skip_config"] {
            
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
            
            let data = CoreManagerResultData(userSource: CoreUserSource(rawValue: xc_network), activePaywallName: xc_activePaywallName, isActivePaywallDefault: true, paywallsBySource: [CoreUserSource(rawValue: xc_network) : xc_activePaywallName])
            let result = CoreManagerResult.success(data: data)
            
            purchaseManager = PurchasesManager.shared
            purchaseManager?.initialize(allIdentifiers: configuration.paywallDataSource.allPurchaseIDs, proIdentifiers: configuration.paywallDataSource.allProPurchaseIDs)
            
            self.delegate?.coreConfigurationFinished(result: result)
            return
        }
        
        self.configuration = configuration
        
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
        let configurationEventsModel = CoreConfigurationModel(allConfigurationEvents: allConfigurationEvents)
        AppConfigurationManager.shared = AppConfigurationManager(model: configurationEventsModel,
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

        handleConfigurationEndCallback()
        
        handleAttributionInstall()
    }
    
    @objc public func applicationDidBecomeActive() {
        configureID()
        
        if appsflyerManager?.customerUserID != nil {
            appsflyerManager?.startAppsflyer()
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
                remoteConfigManager?.fetchRemoteConfig(configuration?.remoteConfigDataSource.allConfigurables ?? []) {
                    self.sendAmplitudeAssigned(configs: self.remoteConfigManager?.allRemoteValues ?? [:])
                    self.handleConfigurationUpdate()
                    InternalConfigurationEvent.remoteConfigLoaded.markAsCompleted()
                }
                return
            }
            idConfigured = true
            
            appsflyerManager?.customerUserID = id
            purchaseManager?.setUserID(id)
            self.facebookManager?.userID = id
            sentryManager.setUserID(id)
            
            self.remoteConfigManager?.configure(id: id) { [weak self] in
                guard let self = self else {return}
                remoteConfigManager?.fetchRemoteConfig(configuration?.remoteConfigDataSource.allConfigurables ?? []) {
                    self.sendAmplitudeAssigned(configs: self.remoteConfigManager?.allRemoteValues ?? [:])
                    self.handleConfigurationUpdate()
                    InternalConfigurationEvent.remoteConfigLoaded.markAsCompleted()
                }
            }
            
            self.analyticsManager?.setUserID(id)
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
            self?.handleATTAnswered(status)
        }
            
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            guard self?.attAnswered == false else { return }
            self?.attAnswered = true
            
            self?.sendAttEvent(answer: status == .authorized)
            self?.handleATTAnswered(status)
        }
    }
    
    func handleATTAnswered(_ status: ATTrackingManager.AuthorizationStatus) {
        AppConfigurationManager.shared?.startTimoutTimer()
        InternalConfigurationEvent.attConcentGiven.markAsCompleted()
        facebookManager?.configureATT(isAuthorized: status == .authorized)
    }
    
    func handleAttributionInstall() {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
    
        configurationManager.signForAttAndConfigLoaded {
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
                if let serverDataSource = self.configuration?.attributionServerDataSource {
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
                InternalConfigurationEvent.attributionServerHandled.markAsCompleted()
            }
        }

    }
    
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
    
    func handleConfigurationEndCallback() {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        
        configurationManager.signForConfigurationEnd { configurationResult in
            self.configurationEndQueue.async {
                let result = self.getConfigurationResult(isFirstConfiguration: true)
                self.delegate?.coreConfigurationFinished(result: result)
            }
            // calculate attribution
            // calculate correct paywall name
            // return everything to the app
        }
    }
    
    func handleConfigurationUpdate() {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        
        if configurationManager.configurationFinishHandled {
            self.configurationEndQueue.async {
                let result = self.getConfigurationResult(isFirstConfiguration: false)
                self.delegate?.coreConfigurationUpdated(newResult: result)
            }
        }
    }
    
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
    
    func getConfigurationResult(isFirstConfiguration: Bool) -> CoreManagerResult {
        let abTests = self.configuration?.remoteConfigDataSource.allABTests ?? InternalRemoteABTests.allCases
        let remoteResult = self.remoteConfigManager?.allRemoteValues ?? [:]
        let asaResult = AttributionServerManager.shared.installResultData
        let isIPAT = asaResult?.isIPAT ?? false
        let deepLinkResult = self.appsflyerManager?.deeplinkResult ?? [:]
        let isASA = (asaResult?.asaAttribution["campaignName"] as? String != nil) ||
        (asaResult?.asaAttribution["campaign_name"] as? String != nil)
        
        if checkIsNoInternetHandledOrIgnored() == false {
            //guard remoteResult.isEmpty && asaResult == nil && deepLinkResult.isEmpty else {
            if remoteResult.isEmpty && asaResult == nil && deepLinkResult.isEmpty {
                AppConfigurationManager.shared?.reset()
                attAnswered = false
                handleAttributionInstall()
                handleConfigurationEndCallback()
                let result = self.configurationResultManager.calculateResult()
                return CoreManagerResult.error(data: result)
            }
        }
        
        var isRedirect = false
        var networkSource: CoreUserSource = .unknown
        
        if let networkValue = deepLinkResult["network"] {
            if networkValue.contains("web2app_fb") {
                networkSource = .facebook
            } else if networkValue.contains("Google_StoreRedirect") {
                networkSource = .google
            } else if networkValue.contains("tiktok") {
                networkSource = .tiktok
            } else if networkValue.contains("instagram") {
                networkSource = .instagram
            } else if networkValue.contains("snapchat") {
                networkSource = .snapchat
            } else if networkValue.lowercased().contains("bing") {
                networkSource = .bing
            } else if networkValue == "Full_Access" {
                networkSource = .test_premium
            } else if networkValue == "restricted" {
                if let fixedSource = self.configuration?.appSettings.paywallSourceForRestricted {
                    networkSource = fixedSource
                }
            } else {
                networkSource = .unknown
            }
            
            isRedirect = true
        }
        
        var userSource: CoreUserSource
        
        if isIPAT {
            userSource = .ipat
        }else if isRedirect {
            userSource = networkSource
        }else if isASA {
            userSource = .asa
        }else {
            userSource = .organic
        }
        
        if isFirstConfiguration {
            self.sendABTestsUserProperties(abTests: abTests, userSource: userSource)
            self.sendTestDistributionEvent(abTests: abTests, deepLinkResult: deepLinkResult, userSource: userSource)
        } else {
            self.sendABTestsUserProperties(abTests: abTests, userSource: userSource)
        }
        
        self.configurationResultManager.userSource = userSource
        self.configurationResultManager.deepLinkResult = deepLinkResult
        self.configurationResultManager.asaAttributionResult = asaResult?.asaAttribution
        
        let result = self.configurationResultManager.calculateResult()
           
        return CoreManagerResult.success(data: result)
    }
}

class ConfigurationResultManager {
    var userSource: CoreUserSource = .organic
    var asaAttributionResult: [String: String]?
    var deepLinkResult: [String: String]?
    
    func calculateResult() -> CoreManagerResultData {
        // get appsflyer info
        var paywallsBySource = [CoreUserSource: PaywallInfo]()
        InternalRemoteABTests.allCases.forEach { config in
            let value = config.value
            let paywall = self.getPaywallNameFromConfig(value)
            if config.activeForSources.count != 1 {
                assertionFailure()
            }
            if let source = config.activeForSources.first {
                paywallsBySource[source] = paywall
            }
        }
        
        let activePaywallName: String
        let activePaywallIsDefault: Bool
        var userSourceInfo: [String: String]? = deepLinkResult
        
        if let deepLinkValue: String = deepLinkResult?["deep_link_value"], deepLinkValue != "none", deepLinkValue != "",
           let firebaseValue = CoreManager.internalShared.remoteConfigManager?.allRemoteValues[deepLinkValue] {
            let activePaywallInfo = getPaywallNameFromConfig(firebaseValue)
            activePaywallName = activePaywallInfo.name
            activePaywallIsDefault = activePaywallInfo.isDefault
            userSourceInfo = deepLinkResult
        } else {
            let organicConfigValue = InternalRemoteABTests.ab_paywall_organic.value
            
            switch userSource {
            case .organic, .ipat, .test_premium, .unknown:
                if let organicPaywall = paywallsBySource[CoreUserSource.organic] {
                    activePaywallName = organicPaywall.name
                    activePaywallIsDefault = organicPaywall.isDefault
                } else {
                    assertionFailure()
                    activePaywallName = organicConfigValue
                    activePaywallIsDefault = true
                }
            default:
                if let paywallBySource = paywallsBySource[userSource] {
                    activePaywallName = paywallBySource.name
                    activePaywallIsDefault = paywallBySource.isDefault
                } else {
                    assertionFailure()
                    activePaywallName = organicConfigValue
                    activePaywallIsDefault = true
                }
            }
        }
        
        let paywallNamesBySource = paywallsBySource.reduce(into: [CoreUserSource: String]()) { partialResult, paywallInfo in
            partialResult[paywallInfo.key] = paywallInfo.value.name
        }
        
        let result = CoreManagerResultData(userSource: userSource,
                                           userSourceInfo: userSourceInfo,
                                           activePaywallName: activePaywallName,
                                           isActivePaywallDefault: activePaywallIsDefault,
                                           paywallsBySource: paywallNamesBySource)
        return result
    }
    
    private func getPaywallNameFromConfig(_ config: String) -> PaywallInfo {
        let paywallName: String
        let isDefault: Bool
        let value = config
        if value.hasPrefix("none_") {
            paywallName = String(value.dropFirst("none_".count))
            isDefault = true
        } else {
            paywallName = value
            isDefault = false
        }
        return PaywallInfo(name: paywallName, isDefault: isDefault)
    }
    
    struct PaywallInfo {
        let name: String
        let isDefault: Bool
    }
}

typealias PaywallName = String
enum PaywallDefaultType {
    case organic
    case web2app
    case fb_google_redirect
    
    var defaultPaywallName: PaywallName {
        return "default"
    }
}
