#if !COCOAPODS
import RemoteTestingIntegration
#endif

import Foundation

enum InternalRemoteConfig: String, CoreRemoteConfigurable {
    case subscription_screen_style_full
    case subscription_screen_style_h
    case rate_us_primary_shown
    case rate_us_secondary_shown
    
    case install_server_path
    case purchase_server_path
    
    var key: String { return rawValue }
    
    var activeForSources: [CoreUserSource] {
        return CoreUserSource.allCases
    }
    
    var defaultValue: String { return "" }
}

enum InternalRemoteABTests: String, CoreRemoteABTestable {    
    // Framework
    case ab_paywall_fb
    case ab_paywall_google
    case ab_paywall_asa
    case ab_paywall_snapchat
    case ab_paywall_tiktok
    case ab_paywall_instagram
    case ab_paywall_bing
    case ab_paywall_organic
    case ab_paywall
    
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
        case .ab_paywall_snapchat:
            return [.snapchat]
        case .ab_paywall_tiktok:
            return [.tiktok]
        case .ab_paywall_instagram:
            return [.instagram]
        case .ab_paywall_bing:
            return [.bing]
        case .ab_paywall:
            return CoreUserSource.allCases
        }
    }
}

