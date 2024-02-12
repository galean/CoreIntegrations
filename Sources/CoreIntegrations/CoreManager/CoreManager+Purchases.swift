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
        let result = await skCoordinator.requestProducts(config.activeForPaywallIDs)
        switch result {
        case .success(let products):
            let purchases = mapProducts(products)
            return .success(purchases: purchases)
        case .error(let error):
            return .error(error: error)
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
}
