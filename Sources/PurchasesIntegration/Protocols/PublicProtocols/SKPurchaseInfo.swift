//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 13/2/24.
//

import Foundation
import StoreKit

public struct SKPurchaseInfo {
    public let transaction: Transaction
    public let jsonRepresentation: Data
    public let jwsRepresentation: String
    public let originalID: String
}
