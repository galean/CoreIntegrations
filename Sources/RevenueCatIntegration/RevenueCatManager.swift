//
//  RevenueCatManager.swift
//  
//
//  Created by Andrii Plotnikov on 03.10.2023.
//

import Foundation
import RevenueCat

public class RevenueCatManager: NSObject {
    private let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public var storedOfferings: Offerings?
    
    public func configure(uuid: String, appsflyerID: String?, fbAnonID: String?, completion: @escaping (Bool?) -> Void) {
        guard Purchases.isConfigured == false else {
            completion(nil)
            return
        }
        Purchases.configure(withAPIKey: self.apiKey, appUserID: uuid)
        Purchases.shared.delegate = nil
        Purchases.shared.attribution.collectDeviceIdentifiers()
        if let fbAnonID {
            Purchases.shared.attribution.setFBAnonymousID(fbAnonID)
        }
        if let appsflyerID {
            Purchases.shared.attribution.setAppsflyerID(appsflyerID)
        }
        Purchases.shared.attribution.setAttributes(["$amplitudeUserId": uuid])
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
        syncPurchases()
        offerings { offerings in
            completion(offerings != nil)
        }
    }
    
    public func syncPurchases() {
        let isAlreadySynched = UserDefaults.standard.bool(forKey: "TLMCORE_RC_SYNCHED_PURCHASES")
        guard isAlreadySynched == false else {
            return
        }
        Purchases.shared.syncPurchases { info, error in
            guard error == nil else {
                return
            }
            UserDefaults.standard.set(true, forKey: "TLMCORE_RC_SYNCHED_PURCHASES")
        }
    }
    
    public func package(withID packageID: String, inOfferingWithID offeringID: String, completion: @escaping (_ package: Package?) -> Void) {
        offering(withID: offeringID) { offering in
            guard let offering else {
                completion(nil)
                return
            }
            
            let package = offering.package(identifier: packageID)
            completion(package)
        }
    }
    
    public func offering(withID id: String, completion: @escaping (_ offering: Offering?) -> Void) {
        offerings { offerings in
            guard let offerings else {
                completion(nil)
                return
            }
            
            let offering = offerings.offering(identifier: id)
            completion(offering)
        }
    }
    
    public func offerings(completion: @escaping (_ offerings: Offerings?) -> Void) {
        guard Purchases.isConfigured else {
            completion(nil)
            return
        }
        
        
        Purchases.shared.getOfferings {[weak self] offerings, error in
            guard let offerings, error == nil else {
                completion(nil)
                return
            }
            self?.storedOfferings = offerings
            completion(offerings)
        }
    }
    
    public func purchase(_ package: Package) async -> RevenueCatPurchaseResult {
        guard Purchases.isConfigured else {
//            completion()
            return .error(error: "Integration error")
        }
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            switch result {
            case (let transaction, let customerInfo, let userCancelled):
                if userCancelled == true {
                    return .userCancelled
                } else {
                    let product = package.storeProduct
                    let isSubscription = product.productType == .autoRenewableSubscription || product.productType == .nonRenewableSubscription
                    let info = RevenueCatPurchaseInfo(isSubscription: isSubscription, productID: product.productIdentifier,
                                            price: product.priceFloat, introductoryPrice: product.introPrice,
                                            currencyCode: product.currencyCode ?? "", transactionID: transaction?.transactionIdentifier ?? "")
                    return .success(info: info)
                }
            }
        } catch {
            return .error(error: "Integration error")
        }
    }
    
    public func purchase(_ package: Package, completion: @escaping (RevenueCatPurchaseResult) -> Void) {
        guard Purchases.isConfigured else {
            completion(.error(error: "Integration error"))
            return
        }
        
        Purchases.shared.purchase(package: package) { transaction, purchaseInfo, error, userCancelled in
            if userCancelled == true {
                completion(.userCancelled)
            } else if let error {
                completion(.error(error: error.description))
            } else if let purchaseInfo {
                let product = package.storeProduct
                let isSubscription = product.productType == .autoRenewableSubscription || product.productType == .nonRenewableSubscription
                let info = RevenueCatPurchaseInfo(isSubscription: isSubscription, productID: product.productIdentifier,
                                                  price: product.priceFloat, introductoryPrice: product.introPrice,
                                                  currencyCode: product.currencyCode ?? "",
                                                  transactionID: transaction?.transactionIdentifier ?? "")
                completion(.success(info: info))
            } else {
                completion(.error(error: "Something went wrong"))
            }
        }
    }
    
    public func verifyPremium(completion: @escaping (_ result: RevenueCatVerifyPremiumResult) -> Void) {
        guard Purchases.isConfigured else {
            completion(.error)
            return
        }
        
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            guard error == nil, let customerInfo else {
                completion(.error)
                return
            }
            
            let isPro = customerInfo.entitlements["Pro"]?.isActive == true
            
            if isPro {
                guard let proEntitlement = customerInfo.entitlements["Pro"] else {
                    completion(.error)
                    return
                }
                
                let purchaseID = proEntitlement.productIdentifier
                completion(.premium(subscriptionID: purchaseID))
            } else {
                completion(.notPremium)
            }
        }
    }
    
    public func restorePremium(completion: @escaping (_ result: RevenueCatVerifyPremiumResult) -> Void) {
        guard Purchases.isConfigured else {
            completion(.error)
            return
        }
        
        Purchases.shared.restorePurchases { (customerInfo, error) in
            guard error == nil, let customerInfo else {
                completion(.error)
                return
            }
            
            let isPro = customerInfo.entitlements["Pro"]?.isActive == true
            
            if isPro {
                guard let proEntitlement = customerInfo.entitlements["Pro"] else {
                    completion(.error)
                    return
                }
                
                let purchaseID = proEntitlement.productIdentifier
                completion(.premium(subscriptionID: purchaseID))
            } else {
                completion(.notPremium)
            }
        }
    }
    
    public func verifyPurchases(completion: @escaping (_ result: RevenueCatRestoreResult) -> Void) {
        guard Purchases.isConfigured else {
            completion(.error)
            return
        }
        
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            guard error == nil, let customerInfo else {
                completion(.error)
                return
            }
            
            let nonSubscriptionIds = customerInfo.nonSubscriptions.map { transaction -> String in
                return transaction.productIdentifier
            }
            let nonSubscriptionsSet = Set(nonSubscriptionIds)

            completion(.success(subscriptions: customerInfo.activeSubscriptions,
                                nonSubscriptions: nonSubscriptionsSet))
        }
    }
    
    public func restorePurchases(completion: @escaping (_ result: RevenueCatRestoreResult) -> Void) {
        guard Purchases.isConfigured else {
            completion(.error)
            return
        }
        
        Purchases.shared.restorePurchases { (customerInfo, error) in
            guard error == nil, let customerInfo else {
                completion(.error)
                return
            }
            
            let entitlements = customerInfo.entitlements
            let nonSubscriptionIds = customerInfo.nonSubscriptions.map { transaction -> String in
                return transaction.productIdentifier
            }
            let nonSubscriptionsSet = Set(nonSubscriptionIds)
            
            completion(.success(entitlements: entitlements,
                                nonSubscriptions: nonSubscriptionsSet))
        }
    }
}

extension RevenueCatManager: PurchasesDelegate {
    public func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        
    }
}

extension StoreProduct {
    var priceFloat: CGFloat {
        CGFloat(NSDecimalNumber(decimal: price).floatValue)
    }
    
    var introPrice: CGFloat? {
        guard let intro = introductoryDiscount else {
            return nil
        }
        
        return CGFloat(NSDecimalNumber(decimal: intro.price).floatValue)
    }
}

