//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation
import SwiftyStoreKit
import StoreKit

public enum PurchasesPurchaseResult {
    case success(details: PurchaseDetails)
    case cancelled
    case internetError
    case deferredPurchase
    case error(skerror: SKError)
}
