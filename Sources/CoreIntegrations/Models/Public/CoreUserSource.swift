
import Foundation

public enum CoreUserSource: CaseIterable, Hashable, Sendable, RawRepresentable {
    case organic
    case asa
    case facebook
    case google
    case ipat
    case test_premium
    case tiktok
    case instagram
    case snapchat
    case bing
    case moloco
    case applovin
    case tiktok_full_access
    case unknown
    
    public typealias RawValue = String
    
    public init(rawValue: String) {
        switch rawValue.lowercased() {
        case "organic": self = .organic
        case "asa": self = .asa
        case "facebook": self = .facebook
        case "google": self = .google
        case "ipat": self = .ipat
        case "test_premium": self = .test_premium
        case "tiktok": self = .tiktok
        case "instagram": self = .instagram
        case "snapchat": self = .snapchat
        case "bing": self = .bing
        case "moloco": self = .moloco
        case "applovin": self = .applovin
        case "tiktok_full_access": self = .tiktok_full_access
        default: self = .unknown
        }
    }
    
    public var rawValue: String {
        switch self {
        case .organic: return "organic"
        case .asa: return "asa"
        case .facebook: return "facebook"
        case .google: return "google"
        case .ipat: return "ipat"
        case .test_premium: return "test_premium"
        case .tiktok: return "tiktok"
        case .instagram: return "instagram"
        case .snapchat: return "snapchat"
        case .bing: return "bing"
        case .moloco: return "moloco"
        case .applovin: return "applovin"
        case .tiktok_full_access: return "tiktok_full_access"
        case .unknown: return "unknown"
        }
    }
}
