//
//  CoreManager.swift
//
//
//  Created by Andrii Plotnikov on 02.02.2023.
//

import UIKit
#if !COCOAPODS
import AppsflyerIntegration
import FacebookIntegration
import AttributionServerIntegration
import AnalyticsIntegration
import FirebaseIntegration
import RevenueCatIntegration
#endif
import AppTrackingTransparency
import Foundation
import StoreKit
import RevenueCat
/*
    I think it would be good to split CoreManager into different manager parts - for default configuration, for additional configurations like analytics, test_distribution etc, and for purchases and purchases attribution part
 */
public class CoreManager {
    public static var shared: CoreManagerProtocol = internalShared
    static var internalShared = CoreManager()
    
    public static var uniqueUserID: String? {
        return AttributionServerManager.shared.uniqueUserID
    }
    
    var isConfigured: Bool = false
    var attAnswered: Bool = false
    
    var configuration: CoreConfigurationProtocol?
    var appsflyerManager: AppfslyerManagerProtocol?
    var facebookManager: FacebookManagerProtocol?
    var revenueCatManager: RevenueCatManager?

    var firebaseManager: FirebaseManager?
    var analyticsManager: AnalyticsManager?
        
    var delegate: CoreManagerDelegate?
    
    var configurationResultManager = ConfigurationResultManager()
    
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
        appsflyerManager?.delegate = self
        
        facebookManager = FacebookManager()
        
        let attributionToken = configuration.appSettings.attributionServerSecret
        let facebookData = AttributionFacebookModel(fbUserId: facebookManager?.userID ?? "",
                                                    fbUserData: facebookManager?.userData ?? "",
                                                    fbAnonId: facebookManager?.anonUserID ?? "")
        let appsflyerToken = appsflyerManager?.appsflyerID
        let installPath = "/install-application"
        let purchasePath = "/subscribe"
        let installURLPath = ""
        let purchaseURLPath = ""
        
       
        revenueCatManager = RevenueCatManager(apiKey: configuration.appSettings.revenuecatApiKey)
        
        firebaseManager = FirebaseManager()
        firebaseManager?.configure()
        
        self.firebaseManager?.fetchRemoteConfig(configuration.remoteConfigDataSource.allConfigurables) {
            InternalConfigurationEvent.remoteConfigLoaded.markAsCompleted()
        }
        
        let attributionConfiguration = AttributionConfigData(authToken: attributionToken,
                                                             installServerURLPath: installURLPath,
                                                             purchaseServerURLPath: purchaseURLPath,
                                                             installPath: installPath,
                                                             purchasePath: purchasePath,
                                                             appsflyerID: appsflyerToken,
                                                             facebookData: facebookData)
        //refactor to accept only attributionToken here
        //url setup's in handleAttributionInstall()
        AttributionServerManager.shared.configure(config: attributionConfiguration)
        
        revenueCatManager = RevenueCatManager(apiKey: configuration.appSettings.revenuecatApiKey)
        
        firebaseManager = FirebaseManager()
        firebaseManager?.configure()
        
        self.firebaseManager?.fetchRemoteConfig(configuration.remoteConfigDataSource.allConfigurables) {
            InternalConfigurationEvent.remoteConfigLoaded.markAsCompleted()
        }
        
        let attributionConfiguration = AttributionConfigData(authToken: attributionToken,
                                                                 installServerURLPath: installURLPath,
                                                                 purchaseServerURLPath: purchaseURLPath,
                                                                 installPath: installPath,
                                                                 purchasePath: purchasePath,
                                                                 appsflyerID: appsflyerToken,
                                                                 facebookData: facebookData)
            
            AttributionServerManager.shared.configure(config: attributionConfiguration)
        
        if configuration.useDefaultATTRequest {
            self.configureATT()
        }
        
        self.handleConfigurationEndCallback()
        
        self.handleAttributionInstall()
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
            facebookManager?.userID = id
            firebaseManager?.setUserID(id)
            analyticsManager?.setUserID(id)
            revenueCatManager?.configure(uuid: id, appsflyerID: self.appsflyerManager?.appsflyerID,
                                         fbAnonID: self.facebookManager?.anonUserID, completion: { isConfigured in

                InternalConfigurationEvent.revenueCatConfigured.markAsCompleted()
            })
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
        
//        var attAnswered = false
        
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
            
            if let installURLPath = self.firebaseManager?.install_server_path,
               let purchaseURLPath = self.firebaseManager?.purchase_server_path {
                let installPath = "/install-application"
                let purchasePath = "/subscribe"
                
                let attributionConfiguration = AttributionConfigURLs(installServerURLPath: installURLPath,
                                                                     purchaseServerURLPath: purchaseURLPath,
                                                                     installPath: installPath,
                                                                     purchasePath: purchasePath)
                
                AttributionServerManager.shared.configureURLs(config: attributionConfiguration)
            }
            
            AttributionServerManager.shared.syncOnAppStart { result in
                InternalConfigurationEvent.attributionServerHandled.markAsCompleted()
            }
        }

    }
    
    func handlePurchaseSuccess(purchaseInfo: RevenueCatPurchaseInfo) {
        self.sendPurchaseToAttributionServer(purchaseInfo)
        self.sendPurchaseToFacebook(purchaseInfo)
        self.sendPurchaseToAppsflyer(purchaseInfo.introductoryPrice != nil)
    }
    
    func sendPurchaseToAttributionServer(_ details: RevenueCatPurchaseInfo) {
        let tlmamDetals = AttributionPurchaseModel(rcDetails: details)
        AttributionServerManager.shared.syncPurchase(data: tlmamDetals)
    }
    
    private func sendPurchaseToFacebook(_ details: RevenueCatPurchaseInfo) {
        guard facebookManager != nil else {
            return
        }
        
        let isTrial = details.introductoryPrice != nil
        let trialPrice = details.introductoryPrice ?? 0
        let price = details.price
        let currencyCode = details.currencyCode
        let analData = FacebookPurchaseData(isTrial: isTrial,
                                            subcriptionID: details.productID,
                                            trialPrice: trialPrice, price: price,
                                            currencyCode: currencyCode)
        self.facebookManager?.sendPurchaseAnalytics(analData)
    }
    
    private func sendPurchaseToAppsflyer(_ isTrial: Bool) {
        guard appsflyerManager != nil else {
            return
        }

        if isTrial {
            self.appsflyerManager?.logTrialPurchase()
        }
    }
    
    func handleConfigurationEndCallback() {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        
        configurationManager.signForConfigurationEnd {
            configurationResult in
            
            let abTests = self.configuration?.remoteConfigDataSource.allABTests ?? InternalRemoteABTests.allCases
            let remoteResult = self.firebaseManager?.remoteConfigResult ?? [:]
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
                } else if networkValue == "Full_Access" {
                    networkSource = .test_premium
                } else {
                    networkSource = .unknown
                }
                
                isRedirect = true
            }
            
            var userSource: CoreUserSource
            
            if isIPAT {
                userSource = .ipat
            } else if isASA {
                userSource = .asa
            } else if isRedirect {
                userSource = networkSource
            } else {
                userSource = .organic
            }
            
            let allConfigs = self.configuration?.remoteConfigDataSource.allConfigurables ?? []
            self.saveRemoteConfig(attribution: userSource, allConfigs: allConfigs, remoteResult: remoteResult)
                        
            self.sendABTestsUserProperties(abTests: abTests, userSource: userSource)
            self.sendTestDistributionEvent(abTests: abTests, deepLinkResult: deepLinkResult, userSource: userSource)

            self.configurationResultManager.userSource = userSource
            self.configurationResultManager.deepLinkResult = deepLinkResult
            self.configurationResultManager.asaAttributionResult = asaResult?.asaAttribution
            
            
            let result = self.configurationResultManager.calculateResult()
            self.delegate?.coreConfigurationFinished(result: result)
            // calculate attribution
            // calculate correct paywall name
            // return everything to the app
        }
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


class ConfigurationResultManager {
    var userSource: CoreUserSource = .organic
    var asaAttributionResult: [String: String]?
    var deepLinkResult: [String: String]?
    
    func calculateResult() -> CoreManagerResult {
        // get appsflyer info
        
        let facebookPaywallName = self.getPaywallNameFromConfig(InternalRemoteABTests.ab_paywall_fb.value)
        let googlePaywallName = self.getPaywallNameFromConfig(InternalRemoteABTests.ab_paywall_google.value)
        let asaPaywallName = self.getPaywallNameFromConfig(InternalRemoteABTests.ab_paywall_asa.value)
        let organicPaywallName = self.getPaywallNameFromConfig(InternalRemoteABTests.ab_paywall_organic.value)
        //tiktok & instagram paywalls should be added later
        
        let activePaywallName: String
        
        if let deepLinkValue: String = deepLinkResult?["deep_link_value"], deepLinkValue != "none", deepLinkValue != "",
           let firebaseValue = CoreManager.internalShared.firebaseManager?.internalConfigResult?[deepLinkValue] {
                activePaywallName = getPaywallNameFromConfig(firebaseValue)
        }else{
            switch userSource {
            case .organic, .ipat, .test_premium, .tiktok, .instagram, .unknown:
                activePaywallName = organicPaywallName
            case .asa:
                activePaywallName = asaPaywallName
            case .facebook:
                activePaywallName = facebookPaywallName
            case .google:
                activePaywallName = googlePaywallName
            }
        }
        
        let coreManagerResult = CoreManagerResult(userSource: userSource,
                                                  activePaywallName: activePaywallName,
                                                  organicPaywallName: organicPaywallName,
                                                  asaPaywallName: asaPaywallName,
                                                  facebookPaywallName: facebookPaywallName,
                                                  googlePaywallName: googlePaywallName)
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
