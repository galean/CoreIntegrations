//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation
import SwiftyStoreKit

public enum PurchasesVerifyPremiumResult {
    case premium(receiptItem: ReceiptItem)
    case notPremium
    case internetError
    case error(receiptError: ReceiptError)
}
