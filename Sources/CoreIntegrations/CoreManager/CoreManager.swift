
import UIKit
#if !COCOAPODS
import AppsflyerIntegration
import FacebookIntegration
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
