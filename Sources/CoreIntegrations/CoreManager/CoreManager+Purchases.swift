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
        let result = await skCoordinator.requestProducts(config.allIdentifiers)
        switch result {
        case .success(let products):
            let purchases = mapProducts(config: config, products: products)
            return .success(purchases: purchases)
        case .error(let error):
            return .error(error: error)
        }
    }
 
    private func mapProducts(config:any CorePaywallConfiguration, products: [Product]) -> [Purchase] {
        let filtered = products.filter({config.allIdentifiers.contains($0.id)})
        
        var purchases:[Purchase] = []
        filtered.forEach { product in
            let purchase = Purchase(product: product)
            purchases.append(purchase)
        }
        return purchases
    }
}
