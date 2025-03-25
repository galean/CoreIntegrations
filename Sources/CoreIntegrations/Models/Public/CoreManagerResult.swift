
import Foundation

public enum CoreManagerResult: Hashable, Sendable {
    case finished
    case noInternet
}

//public struct CoreManagerResultData: Hashable, Sendable {
//    public var userSource: CoreUserSource
//    public var userSourceInfo: [String: String]?
//    public var activePaywallName: String
//    public var isActivePaywallDefault: Bool
//    public var paywallsBySource: [CoreUserSource: String]
//}
