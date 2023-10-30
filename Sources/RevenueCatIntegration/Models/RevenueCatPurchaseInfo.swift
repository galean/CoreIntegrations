//
//  RevenueCatPurchaseInfo.swift
//  
//
//  Created by Andrii Plotnikov on 03.10.2023.
//

import Foundation

public struct RevenueCatPurchaseInfo {
    public let isSubscription: Bool
    public let productID: String
    public let price: CGFloat
    public let introductoryPrice: CGFloat?
    public let currencyCode: String
    public let transactionID: String
    
    public init(isSubscription: Bool, productID: String, price: CGFloat, introductoryPrice: CGFloat?, currencyCode: String, transactionID: String) {
        self.isSubscription = isSubscription
        self.productID = productID
        self.price = price
        self.introductoryPrice = introductoryPrice
        self.currencyCode = currencyCode
        self.transactionID = transactionID
    }
}
