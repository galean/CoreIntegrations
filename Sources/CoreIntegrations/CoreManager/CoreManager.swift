
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
    
    struct AmplitudeCountry {
        //alpha2code - UK, ES, CN
        static let regionCode = Locale.current.regionCode ?? ""
        //alpha3code - UKR, ESP, CHN
        static let countryCode = SKPaymentQueue.default().storefront?.countryCode ?? ""
        
        static var cnCheck: Bool {
            return regionCode == "CN" || countryCode == "CHN"
        }
    }
    
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
    
    var remoteConfigManager: CoreRemoteConfigManager?
    var analyticsManager: AnalyticsManager?
    
    var delegate: CoreManagerDelegate?
        
    func configureAll(configuration: CoreConfigurationProtocol) {
        guard isConfigured == false else {
            return
        }
        isConfigured = true
        
        self.configuration = configuration
        
        analyticsManager = AnalyticsManager.shared
        
        let amplitudeCustomURL = configuration.amplitudeDataSource.customServerURL
        let cnCheck = AmplitudeCountry.cnCheck
        analyticsManager?.configure(appKey: configuration.appSettings.amplitudeSecret, cnConfig: cnCheck, customURL: amplitudeCustomURL)
        
        sendStoreCountryUserProperty()
        configuration.appSettings.launchCount += 1
        if configuration.appSettings.isFirstLaunch {
            sendFirstLaunchEvent()
        }
        
        let allConfigurationEvents: [any ConfigurationEvent] = InternalConfigurationEvent.allCases + (configuration.initialConfigurationDataSource?.allEvents ?? [])
        let configurationEventsModel = CoreConfigurationModel(allConfigurationEvents: allConfigurationEvents)
        AppConfigurationManager.shared = AppConfigurationManager(model: configurationEventsModel,
                                                                 isFirstStart: configuration.appSettings.isFirstLaunch)
        
        appsflyerManager = AppfslyerManager(config: configuration.appsflyerConfig)
        
        
        facebookManager = FacebookManager()
        
        purchaseManager = PurchasesManager.shared
        
        let attributionToken = configuration.appSettings.attributionServerSecret
        let facebookData = AttributionFacebookModel(fbUserId: facebookManager?.userID ?? "",
                                                    fbUserData: facebookManager?.userData ?? "",
                                                    fbAnonId: facebookManager?.anonUserID ?? "")
        let appsflyerToken = appsflyerManager?.appsflyerID
        
        purchaseManager?.initialize(allIdentifiers: configuration.paywallDataSource.allPurchaseIDs, proIdentifiers: configuration.paywallDataSource.allProPurchaseIDs)

        remoteConfigManager = CoreRemoteConfigManager()
        
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
                    InternalConfigurationEvent.remoteConfigLoaded.markAsCompleted()
                }
            }
            
            self.analyticsManager?.setUserID(id)
        }
        
        if configuration?.useDefaultATTRequest == true {
            requestATT()
        }
        
        Task {
            await purchaseManager?.updateProductStatus()
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
            let enabled = CoreManager.internalShared.remoteConfigManager?.config_on ?? false
            self.appsflyerManager?.enabled = enabled
            self.appsflyerManager?.enableDelegate()
            
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
                
                AttributionServerManager.shared.configureURLs(config: attributionConfiguration, isOn: enabled)
            }else{
                if let serverDataSource = self.configuration?.attributionServerDataSource {
                    let installURLPath = serverDataSource.installPath
                    let purchaseURLPath = serverDataSource.purchasePath
                    
                    let attributionConfiguration = AttributionConfigURLs(installServerURLPath: installURLPath,
                                                                         purchaseServerURLPath: purchaseURLPath,
                                                                         installPath: installPath,
                                                                         purchasePath: purchasePath)
                    
                    AttributionServerManager.shared.configureURLs(config: attributionConfiguration, isOn: enabled)
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
            let result = self.getConfigurationResult(isFirstConfiguration: true)
            self.delegate?.coreConfigurationFinished(result: result)
        }
    }
    
    func getConfigurationResult(isFirstConfiguration: Bool) -> CoreManagerResult {
        let abTests = self.configuration?.remoteConfigDataSource.allABTests ?? InternalRemoteABTests.allCases
        let remoteResult = self.remoteConfigManager?.remoteConfigResult ?? [:]
        let asaResult = AttributionServerManager.shared.installResultData
        let isIPAT = asaResult?.isIPAT ?? false
        let isASA = (asaResult?.asaAttribution["campaignName"] as? String != nil) ||
        (asaResult?.asaAttribution["campaign_name"] as? String != nil)
        
        var isRedirect = false
        var networkSource: CoreUserSource = .unknown
        
        var userSource: CoreUserSource
        
        if isIPAT {
            userSource = .ipat
        } else if isASA {
            userSource = .asa
        } else {
            userSource = .organic
        }
        
        if isFirstConfiguration {
            let allConfigs = self.configuration?.remoteConfigDataSource.allConfigurables ?? []
            self.saveRemoteConfig(attribution: userSource, allConfigs: allConfigs, remoteResult: remoteResult)
                        
            self.sendABTestsUserProperties(abTests: abTests, userSource: userSource)
            self.sendTestDistributionEvent(abTests: abTests, userSource: userSource)
        } else {
            let allConfigs = InternalRemoteABTests.allCases
            self.saveRemoteConfig(attribution: userSource, allConfigs: allConfigs, remoteResult: remoteResult)
            self.sendABTestsUserProperties(abTests: abTests, userSource: userSource)
        }
        
        let result = CoreManagerResult(userSource: userSource, userSourceInfo: asaResult?.asaAttribution)
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
                config.updateValue(value)
            }
        }
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
