
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
        
        analyticsManager?.configure(appKey: configuration.appSettings.amplitudeSecret)
        
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
                
        purchaseManager?.initialize(allIdentifiers: configuration.paywallDataSource.allPurchaseIDs, proIdentifiers: configuration.paywallDataSource.allProPurchaseIDs)

        remoteConfigManager = CoreRemoteConfigManager()
        
        let attributionToken = configuration.appSettings.attributionServerSecret
        let facebookData = AttributionFacebookModel(fbUserId: facebookManager?.userID ?? "",
                                                    fbUserData: facebookManager?.userData ?? "",
                                                    fbAnonId: facebookManager?.anonUserID ?? "")
        let appsflyerToken = appsflyerManager?.appsflyerID
        
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
    }
    
    func configureATT() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    @objc public func applicationDidBecomeActive() {
        let id = AttributionServerManager.shared.userToken
        purchaseManager?.setUserID(id)
        self.facebookManager?.userID = id
        analyticsManager?.setUserID(id)
        appsflyerManager?.startAppsflyer()
        
        self.remoteConfigManager?.configure(token: id) { [weak self] in
            guard let self = self else {return}
            remoteConfigManager?.fetchRemoteConfig(configuration?.remoteConfigDataSource.allConfigurables ?? []) {
                InternalConfigurationEvent.remoteConfigLoaded.markAsCompleted()
            }
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
    
    func handleConfigurationEndCallback() {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        
        configurationManager.signForConfigurationEnd { configurationResult in
            self.getConfigurationResult()
            self.delegate?.coreConfigurationFinished()
        }
    }
    
    func getConfigurationResult() {
        let abTests = self.configuration?.remoteConfigDataSource.allABTests
        let remoteResult = self.remoteConfigManager?.remoteConfigResult ?? [:]
        
        let allConfigs = self.configuration?.remoteConfigDataSource.allConfigurables ?? []
        self.saveRemoteConfig(allConfigs: allConfigs, remoteResult: remoteResult)
        
        guard let abTests else {
            return
        }
        self.sendABTestsUserProperties(abTests: abTests)
        self.sendTestDistributionEvent(abTests: abTests)
    }
    
    func saveRemoteConfig(allConfigs: [any CoreFirebaseConfigurable],
                          remoteResult: [String: String]) {
        allConfigs.forEach { config in
            let remoteValue = remoteResult[config.key]
            
            guard let remoteValue else {
                return
            }
            
            let value = remoteValue
            config.updateValue(value)
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
