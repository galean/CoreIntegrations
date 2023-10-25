//
//  CoreManagerProtocol.swift
//
//
//  Created by Andrii Plotnikov on 03.10.2023.
//
import UIKit
import PurchasesIntegration
import AppsflyerIntegration
import AttributionServerIntegration
import AppTrackingTransparency
import AnalyticsIntegration
import FirebaseIntegration

//public struct CoreManagerResult {
//    var isIPAT: Bool
//    var paywallName: String
//    var organicPaywallName: String
//    var fbgoogleredictedPaywallName: String
//}

public protocol CoreManagerProtocol {
    static var shared: CoreManagerProtocol { get }
    static var uniqueUserID: String? { get }
//    static var publicResult: CoreManagerResult { get }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
                     coreCofiguration configuration: CoreConfigurationProtocol,
                     coreDelegate delegate: CoreManagerDelegate)
//    func applicationDidBecomeActive()
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] ) -> Bool
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    func handleATTPermission(_ status: ATTrackingManager.AuthorizationStatus)
    func purchase(_ purchaseID: String, quantity: Int, atomically: Bool,
                  completion: @escaping (_ result: PurchasesPurchaseResult) -> Void)
    /**
     Called to check is user - a premium user, typically in all our applications all purchases make user premium. But to make it more correct - you provide Sets or subscriptions or purchases, if at least one of them is paid and active - user is considered as a premium and method is returning this purchase details.  
     You typically use this method calling by a "Restore" button on the paywall, and also on application start, to check is user still a premium user and can use all your premium features
     */
    func verifyPremium(premiumSubscriptionIds: Set<String>,
                       premiumPurchaseIds: Set<String>,
                       completion: @escaping (_ result: PurchasesVerifyPremiumResult) -> Void)
    /**
     This method is more specific, typically in 95% of our applications you shouldn't use it. It's specifically to check ALL given purchases are paid or not and gives a list of all of such. It can be used if you have several subscription groups in the app, or different non-consumables to unlock different feature, so then you can use this method to get all paid purchases and then handle the result to lock/unlock different features.
     */
    func restore(subscriptionIds: Set<String>,
                 purchaseIds: Set<String>,
                 completion: @escaping (_ result: PurchasesVerifyResult) -> Void)
}
