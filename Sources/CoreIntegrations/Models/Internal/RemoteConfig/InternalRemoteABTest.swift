//
//  InternalRemoteABTests.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation

enum InternalRemoteABTests: String, CoreRemoteABTestable {
    // Framework
    case ab_paywall_general
    case ab_paywall_fb_google
    
    var key: String { return rawValue }
    
    var defaultValue: String { return "none" }
    
    var boolValue: Bool { return false }
    
    var activeForSources: [CoreUserSource] {
        switch self {
        case .ab_paywall_general:
            return [.organic, .asa]
        case .ab_paywall_fb_google:
            return [.fbgoogle]
        }
    }
}
