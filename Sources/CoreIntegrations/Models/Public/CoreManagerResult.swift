
import Foundation

public struct CoreManagerResult: Hashable, Sendable {
    public var userSource: CoreUserSource
    public var userSourceInfo: [String: String]?
    public var activePaywallName: String
    public var organicPaywallName: String
    public var asaPaywallName: String
    public var facebookPaywallName: String
    public var googlePaywallName: String
    public var snapchatPaywallName: String
    public var tiktokPaywallName: String
    public var instagramPaywallName: String
    public var bingPaywallName: String
    public var molocoPaywallName: String
    public var applovinPaywallName: String
}
