//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation

public struct AttributionPurchaseModel: Codable {
    let price: CGFloat
    let introductoryPrice: CGFloat?
    let currencyCode: String
    let subscriptionIdentifier: String
    let jws: String?
    
    public init(price: CGFloat, introductoryPrice: CGFloat?,
                currencyCode: String, subscriptionIdentifier: String, jws: String?) {
        self.price = price
        self.introductoryPrice = introductoryPrice
        self.currencyCode = currencyCode
        self.subscriptionIdentifier = subscriptionIdentifier
        self.jws = jws
    }
}
