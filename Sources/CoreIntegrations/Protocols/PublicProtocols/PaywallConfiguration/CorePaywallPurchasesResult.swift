//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 1/2/24.
//

import Foundation
import PurchasesIntegration

public enum CorePaywallPurchasesResult {
    case success(purchases: [Purchase])
    case error(error: String)
}
