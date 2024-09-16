
import Foundation
#if !COCOAPODS
import AnalyticsIntegration
#endif

enum InternalUserProperty: String, CaseIterable, AmplitudeAnalyzableUserProperty {
    case app_environment
    case att_status
    case store_country
    case subscription_type
    case app_environment

    public var key: String {
        return rawValue
    }
}
