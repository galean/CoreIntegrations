//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 15/2/24.
//

import Foundation

public struct PromoOffer {
    let offerID: String
    let keyID: String
    let nonce: UUID
    let signature: Data
    let timestamp: Int
}
