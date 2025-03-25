
import Foundation
#if !COCOAPODS
import AnalyticsIntegration
#endif

enum InternalAnalyticsEvent: String, CaseIterable, AmplitudeAnalyzableEvent {
    case first_launch
//    case user_attributed
    case test_distribution
    case test_distribution_update
    case att_permission
    
    public var key: String {
        return rawValue
    }
}
