
import Foundation

public enum CoreUserSource: CaseIterable {
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
    case unknown
    
    static var mostCases: [CoreUserSource] {
        return [.organic, .asa, .facebook, .google, .test_premium, .tiktok, .instagram, .snapchat, .bing, .unknown]
    }
}
