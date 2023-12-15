//
//  InternalRemoteABTests.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation

enum InternalRemoteABTests: String, CoreRemoteABTestable {
    // Framework
    case ab_paywall_fb
    case ab_paywall_google
    case ab_paywall_asa
    case ab_paywall_organic
    
    var key: String { return rawValue }
    
    var defaultValue: String { return "none" }
    
    var boolValue: Bool { return false }
    
    var activeForSources: [CoreUserSource] {
        switch self {
        case .ab_paywall_fb:
            return [.facebook]
        case .ab_paywall_google:
            return [.google]
        case .ab_paywall_asa:
            return [.asa]
        case .ab_paywall_organic:
            return [.organic]
        }
    }
}
