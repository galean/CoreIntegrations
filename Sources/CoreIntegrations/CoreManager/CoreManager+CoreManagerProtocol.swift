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
    
    #warning("add correct response, not transaction: Transaction?, status:SKPurchaseStatus")
    public func purchase(_ purchase: Purchase) async -> PurchasesIntegration.PurchasesPurchaseResult {
        let result = await purchaseManager?.purchase(purchase.product) // -> case success(transaction: Transaction?, status:SKPurchaseStatus)
        return .cancelled
        #warning("add stuff below")
        //                self.sendSubscriptionTypeUserProperty(identifier: details.productId)
        //                self.sendPurchaseToAttributionServer(details)
        //                self.sendPurchaseToFacebook(details)
        //                self.sendPurchaseToAppsflyer(details)
    }
    
    public func verifyPremium() async -> Bool {
        guard let purchaseManager = purchaseManager else {return false}
        let isPremium = await purchaseManager.verifyPremium()
        return isPremium
#warning("add stuff below")
        //            case .premium(let receiptItem):
        //                self.sendSubscriptionTypeUserProperty(identifier: receiptItem.productId)
    }
    
    public func restore() async -> Bool {
        guard let purchaseManager = purchaseManager else {return false}
        let isRestored = await purchaseManager.restore()
        return isRestored
    }
    
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
    
}
