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
    
    case ab_paywall
    
    case minimal_supported_app_version
    
    var key: String { return rawValue }
    
    var defaultValue: String {
        switch self {
        case .ab_paywall:
            return "none"
        case .minimal_supported_app_version:
            return "0"
        default:
            return ""
        }
    }
    
    var stickyBucketed: Bool {
        return false
    }
}

