//
//  RevenueCatPurchaseResult.swift
//  
//
//  Created by Andrii Plotnikov on 03.10.2023.
//

import Foundation

public enum RevenueCatPurchaseResult {
    case success(info: RevenueCatPurchaseInfo)
    case error(error: String)
    case userCancelled
}
