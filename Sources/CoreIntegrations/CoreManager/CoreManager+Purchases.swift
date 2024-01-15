//
//  CoreManager+PaywallName.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
import RevenueCat

extension CoreManager {
    public func purchases(config:any CorePaywallConfiguration) async -> CorePaywallPurchasesResult {
        guard let revenueCatManager else {
            assertionFailure()
            return .error(error: "Integration error")
        }
        if let storedOfferings = revenueCatManager.storedOfferings {
            let purchases = mapPurchases(config: config, offerings: storedOfferings)
            return .success(purchases: purchases)
        }
        let result = await revenueCatManager.offerings()
        switch result {
        case .success(let offerings):
            let purchases = mapPurchases(config: config, offerings: offerings)
            return .success(purchases: purchases)
        case .error(let error):
            return .error(error: error.localizedLowercase)
        }
        
    }
    
    public func purchases(config:any CorePaywallConfiguration, completion: @escaping (_ result: CorePaywallPurchasesResult) -> Void) {
        guard let revenueCatManager else {
            assertionFailure()
            completion(.error(error: "Integration error"))
            return
        }
        if let storedOfferings = revenueCatManager.storedOfferings {
            let purchases = mapPurchases(config: config, offerings: storedOfferings)
            completion(.success(purchases: purchases))
            return
        }
        revenueCatManager.offerings {[weak self] result in
            switch result {
            case .success(let offerings):
                let purchases = self?.mapPurchases(config: config, offerings: offerings) ?? []
                completion(.success(purchases: purchases))
            case .error(let error):
                completion(.error(error: error.localizedLowercase))
            }
            
        }
    }
    
    public func promoOffers(for purchase: Purchase) async -> CorePaywallPromoOffersResult {
        guard let revenueCatManager else {
            assertionFailure()
            return .error(error: "Integration error")
        }
        
        let result = await revenueCatManager.promoOffers(purchase.package)
        
        switch result {
        case .success(promo: let rkOffers):
            let promoOffers = mapPromoOffers(rkOffers: rkOffers)
            return .success(purchases: promoOffers)
        case .error(let error):
            return .error(error: error)
        }
    }
    
    private func mapPromoOffers(rkOffers: [PromotionalOffer]) -> [PromoOffer] {
        let promoOffers = rkOffers.map({PromoOffer(offer: $0)})
        return promoOffers
    }
    
    private func mapPurchases(config:any CorePaywallConfiguration, offerings: Offerings?) -> [Purchase] {
        guard let offerings = offerings, let offering = offerings[config.id] else {return []}
        var subscriptions:[Purchase] = []
        offering.availablePackages.forEach { package in
            let subscription = Purchase(package: package)
            subscriptions.append(subscription)
        }
        return subscriptions
    }
    
    
}
