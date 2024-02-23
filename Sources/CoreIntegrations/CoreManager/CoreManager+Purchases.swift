//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 1/2/24.
//

import Foundation
import StoreKit
import PurchasesIntegration

extension CoreManager {
    public func purchases(config:any CorePaywallConfiguration) async -> CorePaywallPurchasesResult {
        guard let purchaseManager = purchaseManager else {return .error("purchaseManager == nil")}
        let result = await purchaseManager.requestProducts(config.activeForPaywallIDs)
        switch result {
        case .success(let products):
            var purchases = mapProducts(products)
            purchases = sortPurchases(purchases, ids: config.activeForPaywallIDs)
            return .success(purchases: purchases)
        case .error(let error):
            return .error(error)
        }
    }
 
    private func mapProducts(_ products: [Product]) -> [Purchase] {
        var purchases:[Purchase] = []
        products.forEach { product in
            let purchase = Purchase(product: product)
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
