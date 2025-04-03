
import Foundation

public protocol CorePurchaseGroup: Equatable, CaseIterable, RawRepresentable where RawValue == String {
    static var Pro: Self { get }
}

public extension CorePurchaseGroup {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    var isPro: Bool {
        switch self {
        case .Pro:
            return true
        default:
            return false
        }
    }
}
