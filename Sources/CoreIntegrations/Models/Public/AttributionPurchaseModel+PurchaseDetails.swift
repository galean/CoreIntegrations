//
//  AttributionPurchaseModel+PurchaseDetails.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
import StoreKit
#if !COCOAPODS
import AttributionServerIntegration
import RevenueCatIntegration
#endif

extension AttributionPurchaseModel {
    init(rcDetails: RevenueCatPurchaseInfo) {
        let price = rcDetails.price
        let introductoryPrice = rcDetails.introductoryPrice
        let currencyCode = rcDetails.currencyCode
        let purchaseID = rcDetails.productID
        let jws = rcDetails.jws
        let originalTransactionID = rcDetails.originalTransactionID
        
        self.init(price: price, introductoryPrice: introductoryPrice,
             currencyCode: currencyCode, subscriptionIdentifier: purchaseID,
                  jws: jws, originalTransactionID: originalTransactionID)
    }
}
