
import Foundation
#if !COCOAPODS
import AnalyticsIntegration
#endif

enum InternalAnalyticsEvent: String, CaseIterable, AmplitudeAnalyzableEvent {
    case first_launch
    case framework_attributed
    case framework_finished
    case test_distribution
    case att_permission
    
    public var key: String {
        return rawValue
    }
}
