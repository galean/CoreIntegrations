
import Foundation

enum InternalRemoteABTests: String, CoreRemoteABTestable {
    // Framework
    case ab_paywall
    
    var key: String { return rawValue }
    
    var defaultValue: String { return "none" }
    
    var boolValue: Bool { return false }
    
    var activeForSources: [CoreUserSource] {
        switch self {
        case .ab_paywall:
            return CoreUserSource.mostCases
        }
    }
}

