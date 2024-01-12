//
//  PaywallConfiguration.swift
//  
//
//  Created by Anatolii Kanarskyi on 15/11/23.
//

import Foundation

public protocol CorePaywallConfiguration: CaseIterable {
    var id: String { get }
}

public extension CorePaywallConfiguration {
    static func ==(lhs: any CorePaywallConfiguration, rhs: any CorePaywallConfiguration) -> Bool {
        return lhs.id == rhs.id
    }
    
    //add error to result
    func purchases(completion: @escaping (CorePaywallPurchasesResult) -> Void) {
        CoreManager.internalShared.purchases(config: self) { result in
            completion(result)
        }
    }

    func purchases() async -> CorePaywallPurchasesResult {
        let result = await CoreManager.internalShared.purchases(config: self)
        return result
    }
    
    func promoOffers(for purchase: Purchase) async -> CorePaywallPromoOffersResult {
        let result = await CoreManager.internalShared.promoOffers(purchase: purchase)
        return result
    }
    
}

public enum CorePaywallPurchasesResult {
    case success(purchases: [Purchase])
    case error(error: String)
}

public enum CorePaywallPromoOffersResult {
    case success(purchases: [PromoOffer])
    case error(error: String)
}
