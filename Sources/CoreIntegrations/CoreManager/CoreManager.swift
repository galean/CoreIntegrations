//
//  CoreManager.swift
//
//
//  Created by Andrii Plotnikov on 02.02.2023.
//

import UIKit
import AppsflyerIntegration
import FacebookIntegration
import AttributionServerIntegration
import PurchasesIntegration
import AppTrackingTransparency
import Foundation
import StoreKit
import AnalyticsIntegration
import FirebaseIntegration

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
        
        purchaseManager = PurchasesManager.shared
        
        let attributionToken = configuration.appSettings.attributionServerSecret
        let facebookData = AttributionFacebookModel(fbUserId: facebookManager?.userID ?? "",
                                                    fbUserData: facebookManager?.userData ?? "",
                                                    fbAnonId: facebookManager?.anonUserID ?? "")
        let appsflyerToken = appsflyerManager?.appsflyerID
       
        purchaseManager?.initialize(identifiers: configuration.paywallDataSource.allPurchaseIDs)
        
        firebaseManager = FirebaseManager()
        firebaseManager?.configure()
        
        firebaseManager?.fetchRemoteConfig(configuration.remoteConfigDataSource.allConfigurables) {
            InternalConfigurationEvent.remoteConfigLoaded.markAsCompleted()
        }
        
        let installPath = "/install-application"
        let purchasePath = "/subscribe"
        let installURLPath = ""
        let purchaseURLPath = ""
        
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
            self.firebaseManager?.setUserID(id)
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
            if deepLinkResult["network"] != nil {
                isRedirect = true
            }
            
            var userSource: CoreUserSource
            if isIPAT {
                userSource = .ipat
            } else if isASA {
                userSource = .asa
            } else if isRedirect {
                userSource = .fbgoogle
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
        
        let generalPaywallName = self.getGeneralPaywallName(generalPaywalConfig: InternalRemoteABTests.ab_paywall_general)
        let fbGooglePaywallName = self.getFbGooglePaywallName(fbGooglePaywalConfig: InternalRemoteABTests.ab_paywall_fb_google)
        
        let activePaywallName: String
        switch userSource {
        case .organic, .asa, .ipat:
            activePaywallName = generalPaywallName
        case .fbgoogle:
            activePaywallName = fbGooglePaywallName
        }
        
        let coreManagerResult = CoreManagerResult(userSource: userSource,
                                                  activePaywallName: activePaywallName,
                                                  organicPaywallName: generalPaywallName,
                                                  fbgoogleredictPaywallName: fbGooglePaywallName)
        return coreManagerResult
    }
    
    func getActivePaywallName(generalPaywalConfig: any CoreRemoteABTestable,
                              fbGooglePaywalConfig: any CoreRemoteABTestable,
                              deepLinkResult: [String: String]) -> String {
        let paywallName: String
        if deepLinkResult.isEmpty == false {
            paywallName = getGeneralPaywallName(generalPaywalConfig: generalPaywalConfig)
        } else {
            paywallName = getFbGooglePaywallName(fbGooglePaywalConfig: fbGooglePaywalConfig)
        }
        
        return paywallName
    }
    
    func getGeneralPaywallName(generalPaywalConfig: any CoreRemoteABTestable) -> String {
        return getPaywallNameFromConfig(generalPaywalConfig)

    }
    
    func getFbGooglePaywallName(fbGooglePaywalConfig: any CoreRemoteABTestable) -> String {
        return getPaywallNameFromConfig(fbGooglePaywalConfig)
    }
    
    private func getPaywallNameFromConfig(_ config: any CoreRemoteABTestable) -> String {
        let paywallName: String
        let value = config.value
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
