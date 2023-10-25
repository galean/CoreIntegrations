//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation

internal struct AttrubutionPurchaseRequestModel: Codable {
    let productId: String
    let purchaseId: String
    let userId: String
    let adid: String
    let paymentDetails: PaymentDetails
    
    struct PaymentDetails: Codable {
        let price: CGFloat
        let introductoryPrice: CGFloat
        let currency: String
    }
}
