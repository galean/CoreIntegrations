
import Foundation

public struct SentryConfigData {
    let dsn: String
    let debug: Bool
    var tracesSampleRate: Float = 1.0
    var profilesSampleRate: Float = 1.0
    var shouldCaptureHttpRequests: Bool = true
    var httpCodesRange: NSRange = NSMakeRange(202, 599)
    let handledDomains:[String]?

    public init(dsn: String, debug: Bool, tracesSampleRate: Float = 1.0, profilesSampleRate: Float = 1.0, shouldCaptureHttpRequests: Bool = true, httpCodesRange: NSRange = NSMakeRange(202, 599), handledDomains: [String]? = nil) {
        self.dsn = dsn
        self.debug = debug
        self.tracesSampleRate = tracesSampleRate
        self.profilesSampleRate = profilesSampleRate
        self.shouldCaptureHttpRequests = shouldCaptureHttpRequests
        self.httpCodesRange = httpCodesRange
        self.handledDomains = handledDomains
    }
}
