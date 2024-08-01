//
//  SKRestoreResult.swift
//
//
//  Created by Anatolii Kanarskyi on 8/2/24.
//

import Foundation
import StoreKit

public enum SKRestoreResult {
    case success(products: [Product])
    case error(_ error: String)
}
