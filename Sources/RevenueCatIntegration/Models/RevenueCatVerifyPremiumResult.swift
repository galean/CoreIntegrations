//
//  RevenueCatVerifyPremiumResult.swift
//  
//
//  Created by Andrii Plotnikov on 03.10.2023.
//

import Foundation

public enum RevenueCatVerifyPremiumResult {
    case premium(subscriptionID: String)
    case notPremium
    case error
}
