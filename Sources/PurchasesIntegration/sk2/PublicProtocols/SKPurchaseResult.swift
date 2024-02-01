//
//  SKPurchaseResult.swift
//
//
//  Created by Anatolii Kanarskyi on 1/2/24.
//

import Foundation
import StoreKit

public enum SKPurchaseStatus {
    case success
    case pending
    case userCancelled
    case unknown
}

public enum SKPurchaseResult {
    case success(transaction: Transaction?, status:SKPurchaseStatus)
}
