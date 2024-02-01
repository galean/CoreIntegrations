//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 1/2/24.
//

import Foundation

public enum CorePaywallPurchasesResult {
    case success(purchases: [Purchase])
    case error(error: String)
}
