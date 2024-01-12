//
//  PromoOffer.swift
//  
//
//  Created by Anatolii Kanarskyi on 12/1/24.
//

import Foundation
import RevenueCat

public struct PromoOffer: Hashable {
    let offer: PromotionalOffer
    
    init(offer: PromotionalOffer) {
        self.offer = offer
    }
}
