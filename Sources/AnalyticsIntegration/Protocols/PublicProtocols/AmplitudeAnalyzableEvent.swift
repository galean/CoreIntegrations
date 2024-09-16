
import Foundation

public protocol AmplitudeAnalyzableEvent {
    var key: String { get }
}

public extension AmplitudeAnalyzableEvent {
    func log() {
        AnalyticsManager.shared.amplitudeLog(event: key)
    }
    
    func log(parameter: Any) {
        AnalyticsManager.shared.amplitudeLog(event: key, with: ["answer": parameter])
    }
    
    func log(parameters: [AnyHashable: Any]) {
        AnalyticsManager.shared.amplitudeLog(event: key, with: parameters)
    }
}
