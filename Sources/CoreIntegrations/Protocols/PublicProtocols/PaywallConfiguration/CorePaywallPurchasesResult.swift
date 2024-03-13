//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 1/2/24.
//

import Foundation
#if !COCOAPODS
import PurchasesIntegration
#endif

public enum CorePaywallPurchasesResult {
    case success(purchases: [Purchase])
    case error(_ error: String)
}
