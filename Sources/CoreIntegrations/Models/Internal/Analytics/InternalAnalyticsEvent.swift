
import Foundation
#if !COCOAPODS
import AnalyticsIntegration
#endif

enum InternalAnalyticsEvent: String, CaseIterable, AmplitudeAnalyzableEvent {
    case first_launch
    
#warning("Should be removed after tests")
    case framework_start_delaied
    case framework_attribution_started
    
    case framework_attribution
    case framework_attribution_update
    case framework_finished
    case test_distribution
    case att_permission
    
    public var key: String {
        return rawValue
    }
}
