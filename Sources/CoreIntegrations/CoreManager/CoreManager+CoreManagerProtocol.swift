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
    public func purchase(_ purchase: Purchase) async -> PurchasesPurchaseResult {
        guard let purchaseManager = purchaseManager else {return .error("purchaseManager == nil")}
        let result = try? await purchaseManager.purchase(purchase.product)

        switch result {
        case .success(let purchaseInfo):
            let details = PurchaseDetails(productId: purchase.product.id, product: purchase.product, transaction: purchaseInfo.transaction, jws: purchaseInfo.jwsRepresentation, originalTransactionID: purchaseInfo.originalID, decodedTransaction: purchaseInfo.jsonRepresentation)
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
    
    public func purchase(_ purchase: Purchase, promoOffer: PromoOffer) async -> PurchasesPurchaseResult {
        guard let purchaseManager = purchaseManager else {return .error("purchaseManager == nil")}
        let result = try? await purchaseManager.purchase(purchase.product, promoOffer: promoOffer)

        switch result {
        case .success(let purchaseInfo):
            let details = PurchaseDetails(productId: purchase.product.id, product: purchase.product, transaction: purchaseInfo.transaction, jws: purchaseInfo.jwsRepresentation, originalTransactionID: purchaseInfo.originalID, decodedTransaction: purchaseInfo.jsonRepresentation)
            
            // check if premium group
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
        guard let purchaseManager = purchaseManager else {return .notPremium}
        let result = await purchaseManager.verifyPremium()
        if case .premium(let purchase) = result {
            self.sendSubscriptionTypeUserProperty(identifier: purchase.identifier)
        }
        return result
    }
    
    public func verifyAll() async -> PurchaseVerifyAllResult {
        guard let purchaseManager = purchaseManager else {return .success(consumables: [], nonConsumables: [], subscriptions: [], nonRenewables: [])}
        let result = await purchaseManager.verifyAll()
        
        switch result {
        case .success(consumables: let consumables, nonConsumables: let nonConsumables, subscriptions: let subscriptions, nonRenewables: let nonRenewables):
            let map_consumables = consumables.map({PurchasesIntegration.Purchase(product: $0)})
            let map_nonConsumables = nonConsumables.map({PurchasesIntegration.Purchase(product: $0)})
            let map_subscriptions = subscriptions.map({PurchasesIntegration.Purchase(product: $0)})
            let map_nonRenewables = nonRenewables.map({PurchasesIntegration.Purchase(product: $0)})
            return .success(consumables: map_consumables, nonConsumables: map_nonConsumables, subscriptions: map_subscriptions, nonRenewables: map_nonRenewables)
        }
    }
    
    public func restore() async -> PurchasesRestoreResult {
        guard let purchaseManager = purchaseManager else {return .error("purchaseManager == nil")}
        let result = await purchaseManager.restore()
        
        switch result {
        case .success(consumables: let consumables, nonConsumables: let nonConsumables, subscriptions: let subscriptions, nonRenewables: let nonRenewables):
            let map_consumables = consumables.map({PurchasesIntegration.Purchase(product: $0)})
            let map_nonConsumables = nonConsumables.map({PurchasesIntegration.Purchase(product: $0)})
            let map_subscriptions = subscriptions.map({PurchasesIntegration.Purchase(product: $0)})
            let map_nonRenewables = nonRenewables.map({PurchasesIntegration.Purchase(product: $0)})
            return .restore(consumables: map_consumables, nonConsumables: map_nonConsumables, subscriptions: map_subscriptions, nonRenewables: map_nonRenewables)
        case .error(let error):
            return .error(error)
        }
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
