//
//  CoreManager+CoreManagerProtocol.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
import UIKit
import PurchasesIntegration
import AppTrackingTransparency

extension CoreManager: CoreManagerProtocol {
//    public static var publicResult: CoreManagerResult {
//        return CoreManagerResult(isIPAT: true, paywallName: "default",
//                                 organicPaywallName: "default",
//                                 fbgoogleredictedPaywallName: "default")
//    }
    
    public func application(_ application: UIApplication,
                            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?,
                            coreCofiguration configuration: CoreConfigurationProtocol,
                            coreDelegate delegate: CoreManagerDelegate) {
        self.delegate = delegate
        configureAll(configuration: configuration)
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        appsflyerManager?.application(app, open: url, options: options)
        return (facebookManager?.application(app, open: url, options: options) ?? false)
    }
    
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        appsflyerManager?.application(application, continue: userActivity, restorationHandler: restorationHandler) ?? false
    }
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        appsflyerManager?.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        appsflyerManager?.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    public func handleATTPermission(_ status: ATTrackingManager.AuthorizationStatus) {
        self.sendAttEvent(answer: status == .authorized)
        self.handleATTAnswered(status)
        InternalConfigurationEvent.attConcentGiven.markAsCompleted()
    }
    
    public func purchase(_ purchaseID: String, quantity: Int, atomically: Bool, completion: @escaping (PurchasesIntegration.PurchasesPurchaseResult) -> Void) {
        purchaseManager?.purchase(purchaseID, quantity: quantity, atomically: atomically, completion: {
            result in
            switch result {
            case .success(let details):
                self.sendSubscriptionTypeUserProperty(identifier: details.productId)
                self.sendPurchaseToAttributionServer(details)
                self.sendPurchaseToFacebook(details)
                self.sendPurchaseToAppsflyer(details)
            default:
                break
            }
            
            completion(result)
        })
    }
    
    public func verifyPremium(premiumSubscriptionIds: Set<String>, premiumPurchaseIds: Set<String>, completion: @escaping (PurchasesIntegration.PurchasesVerifyPremiumResult) -> Void) {
        purchaseManager?.verifyPremium(premiumSubscriptionIds: premiumSubscriptionIds,
                                       premiumPurchaseIds: premiumPurchaseIds,
                                       completion: { result in
            switch result {
            case .premium(let receiptItem):
                self.sendSubscriptionTypeUserProperty(identifier: receiptItem.productId)
            default:
                break
            }
            completion(result)
        })
    }
    
    public func restore(subscriptionIds: Set<String>, purchaseIds: Set<String>, completion: @escaping (PurchasesIntegration.PurchasesVerifyResult) -> Void) {
        purchaseManager?.restore(subscriptionIds: subscriptionIds, purchaseIds: purchaseIds,
                                 completion: completion)
    }
}
