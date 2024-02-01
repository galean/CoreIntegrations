//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 1/2/24.
//

import Foundation
import StoreKit

public enum SKProductsResult {
    case success(products: [Product])
    case error(error: String)
}
