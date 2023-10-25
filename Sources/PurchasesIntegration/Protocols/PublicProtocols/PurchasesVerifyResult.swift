//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation
import SwiftyStoreKit

public enum PurchasesVerifyResult {
    case success(restoredItems: [ReceiptItem])
    case nothingToRestore
    case internetError
    case error(receiptError: ReceiptError)
}
