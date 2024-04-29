//
//  CoreManager+CoreManagerProtocol.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
import UIKit
import AppTrackingTransparency
import PurchasesIntegration

extension CoreManager: CoreManagerProtocol {
    public func purchase(_ purchase: Purchase) async -> PurchasesPurchaseResult {
        guard let purchaseManager = purchaseManager else {return .error("purchaseManager == nil")}
        let result = try? await purchaseManager.purchase(purchase.product)

        switch result {
        case .success(let purchaseInfo):
            let details = PurchaseDetails(productId: purchase.product.id, product: purchase.product, transaction: purchaseInfo.transaction, jws: purchaseInfo.jwsRepresentation, originalTransactionID: purchaseInfo.originalID, decodedTransaction: purchaseInfo.jsonRepresentation)
            
            if purchase.purchaseGroup.isPro {
                self.sendSubscriptionTypeUserProperty(identifier: details.productId)
            }
            
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
        let skOffer = SKPromoOffer(offerID: promoOffer.offerID, keyID: promoOffer.keyID, nonce: promoOffer.nonce, signature: promoOffer.signature, timestamp: promoOffer.timestamp)
        let result = try? await purchaseManager.purchase(purchase.product, promoOffer: skOffer)

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
    
    private func groupFor(_ productId: String) -> any CorePurchaseGroup {
        let group = CoreManager.internalShared.configuration?.paywallDataSource.allPurchaseIdentifiers.first(where: {$0.id == productId})?.purchaseGroup
        return group ?? AppPurchaseGroup.Pro
    }

    public func verifyPremium() async -> PurchasesVerifyPremiumResult {
        guard let purchaseManager = purchaseManager else {return .notPremium}
        let result = await purchaseManager.verifyPremium()
        if case .premium(let product) = result {
            self.sendSubscriptionTypeUserProperty(identifier: product.id)
            return .premium(purchase: Purchase(product: product, purchaseGroup: groupFor(product.id)))
        }else{
            self.sendSubscriptionTypeUserProperty(identifier: "")
            return .notPremium
        }
    }
    
    public func verifyAll() async -> PurchaseVerifyAllResult {
        guard let purchaseManager = purchaseManager else {return .success(purchases: [])}
        let result = await purchaseManager.verifyAll()
        
        switch result {
        case .success(products: let products):
            let map_purchases = products.map({Purchase(product: $0, purchaseGroup: groupFor($0.id))})
            
            if let proPurchase = map_purchases.first(where: {$0.purchaseGroup.isPro}) {
                self.sendSubscriptionTypeUserProperty(identifier: proPurchase.identifier)
            }
           
            return .success(purchases: map_purchases)
        }
    }
    
    public func restore() async -> PurchasesRestoreResult {
        guard let purchaseManager = purchaseManager else {return .error("purchaseManager == nil")}
        let result = await purchaseManager.restore()
        
        switch result {
        case .success(products: let products):
            let map_purchases = products.map({Purchase(product: $0, purchaseGroup: groupFor($0.id))})
            
            if let proPurchase = map_purchases.first(where: {$0.purchaseGroup.isPro}) {
                self.sendSubscriptionTypeUserProperty(identifier: proPurchase.identifier)
            }
            
            return .restore(purchases: map_purchases)
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
