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

public protocol CoreManagerProtocol {
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

    func purchase(_ purchase: Purchase) async -> PurchasesPurchaseResult
    
    func verifyPremium() async -> Bool
    
    func restore() async -> Bool
}
