//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 22/2/24.
//

import Foundation

public struct SKPromoOffer {
    let offerID: String
    let keyID: String
    let nonce: UUID
    let signature: Data
    let timestamp: Int
}
