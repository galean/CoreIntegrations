//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation
import StoreKit

public enum PurchasesVerifyPremiumResult {
    case premium(purchase: Purchase)
    case notPremium
}
