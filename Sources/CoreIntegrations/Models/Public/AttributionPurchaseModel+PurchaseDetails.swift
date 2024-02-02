//
//  AttributionPurchaseModel+PurchaseDetails.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
import AttributionServerIntegration
import PurchasesIntegration

extension AttributionPurchaseModel {
    init(swiftyDetails details: PurchaseDetails) {
        let price = CGFloat(NSDecimalNumber(decimal: details.product.price).floatValue)
        let introductoryPrice: CGFloat?
        
        if let introPrice = details.product.subscription?.introductoryOffer?.price {
            introductoryPrice = CGFloat(NSDecimalNumber(decimal: introPrice).floatValue)
        } else {
            introductoryPrice = nil
        }

        let currencyCode = details.product.priceFormatStyle.currencyCode
        let purchaseID = details.product.id
        
        
        self.init(price: price, introductoryPrice: introductoryPrice,
             currencyCode: currencyCode, subscriptionIdentifier: purchaseID)
    }
}
