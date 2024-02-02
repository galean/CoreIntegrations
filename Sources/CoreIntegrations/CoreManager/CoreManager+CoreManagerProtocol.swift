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
    public func purchase(_ purchase: Purchase) async -> PurchasesIntegration.PurchasesPurchaseResult {
        let result = try? await purchaseManager?.purchase(purchase.product)

        switch result {
        case .success(let transaction):
            let details = PurchaseDetails(productId: "", quantity: 1, product: purchase.product, transaction: transaction, needsFinishTransaction: false)
            self.sendSubscriptionTypeUserProperty(identifier: details.productId)
            self.sendPurchaseToAttributionServer(details)
            self.sendPurchaseToFacebook(details)
            self.sendPurchaseToAppsflyer(details)
            return .success(details: details)
        case .pending:
            return .pending
        case .userCancelled:
            return .userCancelled
        case .unknown:
            return .unknown
        case .none:
            return .unknown
        }
    }
    
    public func verifyPremium() async -> PurchasesVerifyPremiumResult {
        guard let purchaseManager = purchaseManager else {return .error(receiptError: "purchaseManager = nil")}
        let result = await purchaseManager.verifyPremium()
        if case .premium(let receiptItem) = result {
            self.sendSubscriptionTypeUserProperty(identifier: receiptItem.id)
        }
        return result
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
