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

enum InternalRemoteConfigs: String, CoreRemoteConfigurable {
    case subscription_screen_style_full
    case subscription_screen_style_h
    case rate_us_primary_shown
    case rate_us_secondary_shown
 
    var key: String { return rawValue }

    var defaultValue: String { return "none" }
    
    var activeForSources: [CoreUserSource] {
        switch self {
        case .subscription_screen_style_full, .subscription_screen_style_h,
                .rate_us_primary_shown, .rate_us_secondary_shown:
            return CoreUserSource.allCases
        }
    }
}
