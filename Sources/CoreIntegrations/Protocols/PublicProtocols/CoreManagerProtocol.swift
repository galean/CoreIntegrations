//
//  CoreManagerProtocol.swift
//
//
//  Created by Andrii Plotnikov on 03.10.2023.
//
import UIKit
import AppsflyerIntegration
import AttributionServerIntegration
import AppTrackingTransparency
import AnalyticsIntegration
import FirebaseIntegration
import RevenueCat
import RevenueCatIntegration

//public struct CoreManagerResult {
//    var isIPAT: Bool
//    var paywallName: String
//    var organicPaywallName: String
//    var fbgoogleredictedPaywallName: String
//}

public protocol CoreManagerProtocol  {
    static var shared: CoreManagerProtocol { get }
    
    static var uniqueUserID: String? { get }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
                     coreCofiguration configuration: CoreConfigurationProtocol,
                     coreDelegate delegate: CoreManagerDelegate)

    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] ) -> Bool
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    func handleATTPermission(_ status: ATTrackingManager.AuthorizationStatus)
    
//    func purchase(_ purchase: Purchase) async -> RevenueCatPurchaseResult
//    func purchase(_ purchase: Purchase, completion: @escaping (_ result: RevenueCatPurchaseResult) -> Void)
    
    func restorePurchases(completion: @escaping (_ result: RevenueCatRestoreResult) -> Void)
    func verifyPurchases(completion: @escaping (_ result: RevenueCatRestoreResult) -> Void)
    func verifyPremium(completion: @escaping (_ result: RevenueCatVerifyPremiumResult) -> Void)
    func restorePremium(completion: @escaping (_ result: RevenueCatVerifyPremiumResult) -> Void)
    
//    func package(withID packageID: String, inOfferingWithID offeringID: String, completion: @escaping (_ package: Package?) -> Void)
//    func offering(withID id: String, completion: @escaping (_ offering: Offering?) -> Void)
//    func offerings(completion: @escaping (_ offerings: Offerings?) -> Void)
//     func storedOfferings() -> Offerings?
    
//    func purchases(config:any PaywallConfiguration, completion: @escaping (_ purchases: [Purchase]) -> Void)
//    func storedPurchases(config:any PaywallConfiguration) -> [Purchase] 
}

