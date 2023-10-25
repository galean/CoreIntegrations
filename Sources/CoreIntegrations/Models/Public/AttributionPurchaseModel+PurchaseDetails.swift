//
//  AttributionPurchaseModel+PurchaseDetails.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
import AttributionServerIntegration
import SwiftyStoreKit

extension AttributionPurchaseModel {
    init(swiftyDetails details: PurchaseDetails) {
        let price = CGFloat(truncating: details.product.price)
        let introductoryPrice: CGFloat?
        if let introPrice = details.product.introductoryPrice?.price {
            introductoryPrice = CGFloat(truncating: introPrice)
        } else {
            introductoryPrice = nil
        }
        let currencyCode = details.product.priceLocale.currencyCode ?? ""
        let purchaseID = details.product.productIdentifier
        
        
        self.init(price: price, introductoryPrice: introductoryPrice,
             currencyCode: currencyCode, subscriptionIdentifier: purchaseID)
    }
}
