//
//  RevenueCatRestoreResult.swift
//  
//
//  Created by Andrii Plotnikov on 03.10.2023.
//

import Foundation
import RevenueCat

public enum RevenueCatRestoreResult {
    case success(entitlements: EntitlementInfos?, subscriptions: Set<String>, nonSubscriptions: Set<String>)
    case error
}
