
import UIKit
#if !COCOAPODS
import AppsflyerIntegration
import FacebookIntegration
import AttributionServerIntegration
import PurchasesIntegration
import AnalyticsIntegration
import FirebaseIntegration
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
        
    var attAnswered: Bool = false
    var isConfigured: Bool = false
    
    var configuration: CoreConfigurationProtocol?
    var appsflyerManager: AppfslyerManagerProtocol?
    var facebookManager: FacebookManagerProtocol?
    var purchaseManager: PurchasesManagerProtocol?
    
    var remoteConfigManager: RemoteConfigManager?
    var analyticsManager: AnalyticsManager?
    
    var delegate: CoreManagerDelegate?
    
    var configurationResultManager = ConfigurationResultManager()
    
    let configurationEndQueue = DispatchQueue(label: "coreIntegrations.manager.endQueue")
    
    var idConfigured = false
    
    func configureAll(configuration: CoreConfigurationProtocol) {
        guard isConfigured == false else {
            return
        }
        isConfigured = true
        
        self.configuration = configuration
        
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
                                                                 isFirstStart: configuration.appSettings.isFirstLaunch)
        
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

        remoteConfigManager = CoreRemoteConfigManager(cnConfig: AppEnvironment.isChina,
                                                      deploymentKey: configuration.appSettings.amplitudeDeploymentKey)
        
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
        
        if configuration.useDefaultATTRequest {
            configureATT()
        }

        handleConfigurationEndCallback()
        
        handleAttributionInstall()
    }
    
    func configureATT() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    @objc public func applicationDidBecomeActive() {
        configureID()
        
        Task {
            await purchaseManager?.updateProductStatus()
        }
    }
    
    private func configureID() {
        guard !idConfigured else {
            return
        }
        idConfigured = true
        
        let savedIDFV = AttributionServerManager.shared.installResultData?.idfv
        let uuid = AttributionServerManager.shared.savedUserUUID
       
        let id: String?
        if savedIDFV != nil {
            id = AttributionServerManager.shared.uniqueUserID
        } else {
            id = uuid ?? AttributionServerManager.shared.uniqueUserID
        }
        if let id, id != "" {
            appsflyerManager?.customerUserID = id
            appsflyerManager?.startAppsflyer()
            purchaseManager?.setUserID(id)
            self.facebookManager?.userID = id
            
            self.remoteConfigManager?.configure(id: id) { [weak self] in
                guard let self = self else {return}
                remoteConfigManager?.fetchRemoteConfig(configuration?.remoteConfigDataSource.allConfigurables ?? []) {
                    if self.remoteConfigManager?.amplitudeOn == true {
                        self.sendAmplitudeAssigned(configs: self.remoteConfigManager?.internalConfigResult ?? [:])
                        self.handleConfigurationUpdate()
                    }
                    InternalConfigurationEvent.remoteConfigLoaded.markAsCompleted()
                }
            }
            
            self.analyticsManager?.setUserID(id)
        }
        
        if configuration?.useDefaultATTRequest == true {
            requestATT()
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
        if let configurationManager = AppConfigurationManager.shared {
            configurationManager.startTimoutTimer()
        } else {
            assertionFailure()
        }
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
            
            if let installURLPath = self.remoteConfigManager?.install_server_path,
               let purchaseURLPath = self.remoteConfigManager?.purchase_server_path,
               installURLPath != "",
               purchaseURLPath != "" {
                let attributionConfiguration = AttributionConfigURLs(installServerURLPath: installURLPath,
                                                                     purchaseServerURLPath: purchaseURLPath,
                                                                     installPath: installPath,
                                                                     purchasePath: purchasePath)
                
                AttributionServerManager.shared.configureURLs(config: attributionConfiguration)
            }else{
                if let serverDataSource = self.configuration?.attributionServerDataSource {
                    let installURLPath = serverDataSource.installPath
                    let purchaseURLPath = serverDataSource.purchasePath
                    
                    let attributionConfiguration = AttributionConfigURLs(installServerURLPath: installURLPath,
                                                                         purchaseServerURLPath: purchaseURLPath,
                                                                         installPath: installPath,
                                                                         purchasePath: purchasePath)
                    
                    AttributionServerManager.shared.configureURLs(config: attributionConfiguration)
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
    
    func getConfigurationResult(isFirstConfiguration: Bool) -> CoreManagerResult {
        let abTests = self.configuration?.remoteConfigDataSource.allABTests ?? InternalRemoteABTests.allCases
        let remoteResult = self.remoteConfigManager?.remoteConfigResult ?? [:]
        let asaResult = AttributionServerManager.shared.installResultData
        let isIPAT = asaResult?.isIPAT ?? false
        let deepLinkResult = self.appsflyerManager?.deeplinkResult ?? [:]
        let isASA = (asaResult?.asaAttribution["campaignName"] as? String != nil) ||
        (asaResult?.asaAttribution["campaign_name"] as? String != nil)
        
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
            let allConfigs = self.configuration?.remoteConfigDataSource.allConfigurables ?? []
            self.saveRemoteConfig(attribution: userSource, allConfigs: allConfigs, remoteResult: remoteResult)
                        
            self.sendABTestsUserProperties(abTests: abTests, userSource: userSource)
            self.sendTestDistributionEvent(abTests: abTests, deepLinkResult: deepLinkResult, userSource: userSource)
        } else {
            let allConfigs = InternalRemoteABTests.allCases
            self.saveRemoteConfig(attribution: userSource, allConfigs: allConfigs, remoteResult: remoteResult)
            self.sendABTestsUserProperties(abTests: abTests, userSource: userSource)
        }
        
        self.configurationResultManager.userSource = userSource
        self.configurationResultManager.deepLinkResult = deepLinkResult
        self.configurationResultManager.asaAttributionResult = asaResult?.asaAttribution
        
        let result = self.configurationResultManager.calculateResult()
        return result
    }
    
    func saveRemoteConfig(attribution: CoreUserSource, allConfigs: [any CoreFirebaseConfigurable],
                          remoteResult: [String: String]) {
        allConfigs.forEach { config in
            let remoteValue = remoteResult[config.key]
            
            guard let remoteValue else {
                return
            }
            
            let value: String
            if config.activeForSources.contains(attribution) {
                value = remoteValue
                remoteConfigManager?.updateValue(forConfig: config, newValue: value)
            }
        }
    }
}

class ConfigurationResultManager {
    var userSource: CoreUserSource = .organic
    var asaAttributionResult: [String: String]?
    var deepLinkResult: [String: String]?
    
    func calculateResult() -> CoreManagerResult {
        // get appsflyer info
        
        let facebookPaywallName = self.getPaywallNameFromConfig(InternalRemoteABTests.ab_paywall_fb.value)
        let googlePaywallName = self.getPaywallNameFromConfig(InternalRemoteABTests.ab_paywall_google.value)
        let asaPaywallName = self.getPaywallNameFromConfig(InternalRemoteABTests.ab_paywall_asa.value)
        let snapchatPaywallName = self.getPaywallNameFromConfig(InternalRemoteABTests.ab_paywall_snapchat.value)
        let tiktokPaywallName = self.getPaywallNameFromConfig(InternalRemoteABTests.ab_paywall_tiktok.value)
        let instagramPaywallName = self.getPaywallNameFromConfig(InternalRemoteABTests.ab_paywall_instagram.value)
        let bingPaywallName = self.getPaywallNameFromConfig(InternalRemoteABTests.ab_paywall_bing.value)
        let organicPaywallName = self.getPaywallNameFromConfig(InternalRemoteABTests.ab_paywall_organic.value)
        
        let activePaywallName: String
        var userSourceInfo: [String: String]? = deepLinkResult
        
        if let deepLinkValue: String = deepLinkResult?["deep_link_value"], deepLinkValue != "none", deepLinkValue != "",
           let firebaseValue = CoreManager.internalShared.remoteConfigManager?.internalConfigResult?[deepLinkValue] {
                activePaywallName = getPaywallNameFromConfig(firebaseValue)
            userSourceInfo = deepLinkResult
        }else{
            switch userSource {
            case .organic, .ipat, .test_premium, .unknown:
                activePaywallName = organicPaywallName
            case .asa:
                activePaywallName = asaPaywallName
                userSourceInfo = asaAttributionResult
            case .facebook:
                activePaywallName = facebookPaywallName
            case .google:
                activePaywallName = googlePaywallName
            case .snapchat:
                activePaywallName = snapchatPaywallName
            case .tiktok:
                activePaywallName = tiktokPaywallName
            case .instagram:
                activePaywallName = instagramPaywallName
            case .bing:
                activePaywallName = bingPaywallName
            }
        }
        
        let coreManagerResult = CoreManagerResult(userSource: userSource,
                                                  userSourceInfo: userSourceInfo,
                                                  activePaywallName: activePaywallName,
                                                  organicPaywallName: organicPaywallName,
                                                  asaPaywallName: asaPaywallName,
                                                  facebookPaywallName: facebookPaywallName,
                                                  googlePaywallName: googlePaywallName,
                                                  snapchatPaywallName: snapchatPaywallName,
                                                  tiktokPaywallName: tiktokPaywallName,
                                                  instagramPaywallName: instagramPaywallName,
                                                  bingPaywallName: bingPaywallName)
        
        return coreManagerResult
    }
    
    private func getPaywallNameFromConfig(_ config: String) -> String {
        let paywallName: String
        let value = config
        if value.hasPrefix("none_") {
            paywallName = String(value.dropFirst("none_".count))
        } else {
            paywallName = value
        }
        return paywallName
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
