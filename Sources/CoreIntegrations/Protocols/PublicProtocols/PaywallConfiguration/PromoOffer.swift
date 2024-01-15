//
//  PromoOffer.swift
//  
//
//  Created by Anatolii Kanarskyi on 12/1/24.
//

import Foundation
import RevenueCat
import StoreKit

public struct PromoOffer: Hashable {
    let offer: PromotionalOffer
    
    init(offer: PromotionalOffer) {
        self.offer = offer
    }
    
    /*
     let discount: StoreProductDiscount
     The StoreProductDiscount in this offer.
     
     let signedData: SignedData
     The PromotionalOffer.SignedData provides information about the PromotionalOffer’s signature.
     */
    
    //MARK: let discount: StoreProductDiscount properties
    
    public var currencyCode: String? {
        return offer.discount.currencyCode
    }
    
    public var description: String {
        return offer.discount.description
    }
    
    public var localizedPriceString: String {
        return offer.discount.localizedPriceString
    }
    
    public var numberOfPeriods: Int {
        return offer.discount.numberOfPeriods
    }
    
    public var offerIdentifier: String? {
        return offer.discount.offerIdentifier
    }
    
    public var paymentMode: Int {
        return offer.discount.paymentMode.rawValue
    }
    
//    public var price: Decimal {
//        return offer.discount.price
//    }
    
    public var price: CGFloat {
        CGFloat(NSDecimalNumber(decimal: offer.discount.price).floatValue)
    }
    
    public var priceDecimalNumber: NSDecimalNumber {
        return offer.discount.priceDecimalNumber
    }
    
    public var sk1Discount: SKProductDiscount? {
        return offer.discount.sk1Discount
    }
    
    public var sk2Discount: StoreKit.Product.SubscriptionOffer? {
        return offer.discount.sk2Discount
    }
    
    public var subscriptionPeriodValue: Int {
        return offer.discount.subscriptionPeriod.value
    }
    
    public var subscriptionPeriodUnit: Int {
        return offer.discount.subscriptionPeriod.unit.rawValue
    }
    
    public var type: Int {
        return offer.discount.type.rawValue
    }
    
    //MARK: let signedData: SignedData properties
    // implement if required
    
    /*
     SignedData:
     Instance Properties
     let identifier: String
     The subscription offer identifier.
     let keyIdentifier: String
     The key identifier of the subscription key.
     let nonce: UUID
     The nonce used in the signature.
     let signature: String
     The cryptographic signature of the offer parameters, generated on RevenueCat’s server.
     let timestamp: Int
     The UNIX time, in milliseconds, when the signature was generated.
     */
}
