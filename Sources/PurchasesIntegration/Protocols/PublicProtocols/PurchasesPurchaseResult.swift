//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation
import StoreKit

public enum PurchasesPurchaseResult {
    case success(details: PurchaseDetails)
    case userCancelled
    case pending
    case unknown
}
