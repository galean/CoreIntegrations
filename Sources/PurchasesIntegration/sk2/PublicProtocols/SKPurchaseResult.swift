//
//  SKPurchaseResult.swift
//
//
//  Created by Anatolii Kanarskyi on 1/2/24.
//

import Foundation
import StoreKit

public enum SKPurchaseResult {
    case success(transaction: SKPurchaseInfo)
    case pending
    case userCancelled
    case unknown
}

public struct SKPurchaseInfo {
    public let transaction: Transaction
    public let jsonRepresentation: Data
    public let jwsRepresentation: String
    public let originalID: String
}
