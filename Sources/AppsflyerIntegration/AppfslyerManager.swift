import UIKit
import AppsFlyerLib

public class AppfslyerManager: NSObject {
    public var delegate: AppsflyerManagerDelegate?
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
    
    private var deepLinkResultUDKey = "coreintegrations_appsflyer_deeplinkResult"
    
    public init(config: AppsflyerConfigData) {
        super.init()
        AppsFlyerLib.shared().appsFlyerDevKey = config.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = config.appleAppID
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 30)
#if DEBUG
        AppsFlyerLib.shared().isDebug = true
#else
        AppsFlyerLib.shared().isDebug = false
#endif
    }
    
    private func parseDeepLink(_ conversionInfo: [AnyHashable : Any]) -> [String: String] {
        var appsFlyerProperties = [String: String]()
        let network = conversionInfo["media_source"] as? String
        if let network {
            appsFlyerProperties["network"] = network
        }
        
        let campaign = conversionInfo["campaign"] as? String
        if let campaign {
            appsFlyerProperties["campaignName"] = campaign
        }
        let adSet = conversionInfo["af_adset"] as? String
        if let adSet {
            appsFlyerProperties["adGroupName"] = adSet
        }
        let ad = conversionInfo["af_ad"] as? String
        if let ad {
            appsFlyerProperties["ad"] = ad
        }
        let dpValue = conversionInfo["deep_link_value"] as? String
        let dpValue1 = conversionInfo["af_dp"] as? String
        if let dpValue {
            appsFlyerProperties["deep_link_value"] = dpValue
        } else if let dpValue1 {
            appsFlyerProperties["deep_link_value"] = dpValue1
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
    
    public func startAppsflyer() {
        AppsFlyerLib.shared().start()
    }
    
    public func logTrialPurchase() {
        AppsFlyerLib.shared().logEvent(AFEventStartTrial, withValues: [:])
    }
}

extension AppfslyerManager: AppsFlyerLibDelegate {
    public func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        let deepLinkInfo = parseDeepLink(conversionInfo)
        deeplinkResult = deepLinkInfo
        delegate?.handledDeeplink(deepLinkInfo)
        delegate?.coreConfiguration(didReceive: conversionInfo)
    }
    
    public func onConversionDataFail(_ error: Error) {
        delegate?.handledDeeplink([:])
        delegate?.coreConfiguration(handleDeeplinkError: error)
        // handle error
    }
    
    public func onAppOpenAttribution(_ attributionData: [AnyHashable : Any]) {
        delegate?.coreConfiguration(handleOnAppOpenAttribution: attributionData)
    }
    
    public func onAppOpenAttributionFailure(_ error: Error) {
        delegate?.coreConfiguration(handleOnAppOpenAttributionError: error)
    }
}

extension AppfslyerManager: DeepLinkDelegate {
    public func didResolveDeepLink(_ result: DeepLinkResult) {
        guard let deeplink = result.deepLink else {
            delegate?.coreConfiguration(didResolveDeeplink: [:])
            return
        }
        
        let description = deeplink.toString()
        let campaign = deeplink.campaign ?? ""
        let campaignId = deeplink.campaignId ?? ""
        let mediaSource = deeplink.mediaSource ?? ""
        let deeplinkValue = deeplink.deeplinkValue ?? ""
        let afSub1 = deeplink.afSub1 ?? ""
        let afSub2 = deeplink.afSub2 ?? ""
        let afSub3 = deeplink.afSub3 ?? ""
        let afSub4 = deeplink.afSub4 ?? ""
        
        let parseResult = ["description": description,
                           "campaign": campaign,
                           "campaignID": campaignId,
                           "mediaSource": mediaSource,
                           "deeplinkValue": deeplinkValue,
                           "afSub1": afSub1,
                           "afSub2": afSub2,
                           "afSub3": afSub3,
                           "afSub4": afSub4]
        
        delegate?.coreConfiguration(didResolveDeeplink: parseResult)
    }
}
