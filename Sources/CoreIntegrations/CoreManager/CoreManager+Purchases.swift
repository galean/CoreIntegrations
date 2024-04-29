//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 1/2/24.
//

import Foundation
import StoreKit

extension CoreManager {
    public func purchases(config:any CorePaywallConfiguration) async -> CorePaywallPurchasesResult {
        guard let purchaseManager = purchaseManager else {return .error("purchaseManager == nil")}
        let result = await purchaseManager.requestProducts(config.activeForPaywallIDs)
        switch result {
        case .success(let products):
            var purchases = mapProducts(products, config)
            purchases = sortPurchases(purchases, ids: config.activeForPaywallIDs)
            return .success(purchases: purchases)
        case .error(let error):
            return .error(error)
        }
    }
 
    private func mapProducts(_ products: [Product], _ config:any CorePaywallConfiguration) -> [Purchase] {
        var purchases:[Purchase] = []
        products.forEach { product in
            let purchaseGroup = config.allPurchases.first(where: {$0.id == product.id})?.purchaseGroup
            let purchase = Purchase(product: product, purchaseGroup: purchaseGroup ?? AppPurchaseGroup.Pro)
            purchases.append(purchase)
        }
        return purchases
    }
    
    private func sortPurchases(_ purchases: [Purchase], ids: [String]) -> [Purchase] {
        return purchases.sorted { f, s in
            guard let first = ids.firstIndex(of: f.identifier) else {
                return false
            }

            guard let second = ids.firstIndex(of: s.identifier) else {
                return true
            }

            return first < second
        }
    }
}
