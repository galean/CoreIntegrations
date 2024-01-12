//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 12/1/24.
//

import Foundation
import RevenueCat

public enum RevenueCatPromoOfferResult {
    case success(promo: [PromotionalOffer])
    case error(error: String)
}
