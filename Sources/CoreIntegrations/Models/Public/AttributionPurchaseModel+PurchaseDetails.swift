//
//  AttributionPurchaseModel+PurchaseDetails.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
import AttributionServerIntegration
import StoreKit
import RevenueCatIntegration

extension AttributionPurchaseModel {
    init(rcDetails: RevenueCatPurchaseInfo) {
        let price = rcDetails.price
        let introductoryPrice = rcDetails.introductoryPrice
        let currencyCode = rcDetails.currencyCode
        let purchaseID = rcDetails.productID
        
        self.init(price: price, introductoryPrice: introductoryPrice,
             currencyCode: currencyCode, subscriptionIdentifier: purchaseID)
    }
}
