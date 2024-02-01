//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation
import StoreKit

public enum PurchasesVerifyResult {
    case success(restoredItems: [Product])
    case nothingToRestore
    case internetError
    case error(receiptError: String)
}
