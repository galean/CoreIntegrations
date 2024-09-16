
import Foundation
#if !COCOAPODS
import AnalyticsIntegration
#endif

enum InternalAnalyticsEvent: String, CaseIterable, AmplitudeAnalyzableEvent {
    case first_launch
    case test_distribution
    case att_permission
    case amplitude_assigned
    
    public var key: String {
        return rawValue
    }
}
