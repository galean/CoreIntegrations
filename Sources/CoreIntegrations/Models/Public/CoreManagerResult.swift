
import Foundation

public enum CoreManagerResult: Hashable, Sendable {
    case success(data: CoreManagerResultData)
    case error(data: CoreManagerResultData)
}

public struct CoreManagerResultData: Hashable, Sendable {
    public var userSource: CoreUserSource
    public var userSourceInfo: [String: String]?
    public var activePaywallName: String
    public var paywallsBySource: [CoreUserSource: String]
}
