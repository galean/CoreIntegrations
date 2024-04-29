//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 15/2/24.
//

import Foundation

public struct SKPromoOffer {
    let offerID: String
    let keyID: String
    let nonce: UUID
    let signature: Data
    let timestamp: Int
    
    public init(offerID: String, keyID: String, nonce: UUID, signature: Data, timestamp: Int) {
        self.offerID = offerID
        self.keyID = keyID
        self.nonce = nonce
        self.signature = signature
        self.timestamp = timestamp
    }
}
