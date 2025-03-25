import Foundation

public protocol CoreRemoteConfigurable: CaseIterable, ExtendedRemoteConfigurable {
    static var subscription_screen_style_full: Self { get }
    static var subscription_screen_style_h: Self { get }
    static var rate_us_primary_shown: Self { get }
    static var rate_us_secondary_shown: Self { get }
    static var ab_paywall: Self { get }
}
