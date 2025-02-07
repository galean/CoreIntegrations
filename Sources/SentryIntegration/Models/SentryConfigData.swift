
import Foundation

public struct SentryConfigData {
    let dsn: String
    let debug: Bool
    var tracesSampleRate: Float = 1.0
    var profilesSampleRate: Float = 1.0
    var appHangTimeoutInterval: TimeInterval = 2.0
    var enableAppHangTracking: Bool = true
    var shouldCaptureHttpRequests: Bool = true
    var httpCodesRange: NSRange = NSMakeRange(202, 599)
    let handledDomains:[String]?
    var diagnosticLevel: UInt = 0

    public init(dsn: String, debug: Bool, tracesSampleRate: Float = 1.0, profilesSampleRate: Float = 1.0, appHangTimeoutInterval: TimeInterval = 2.0, enableAppHangTracking: Bool = true, shouldCaptureHttpRequests: Bool = true, httpCodesRange: NSRange = NSMakeRange(202, 599), handledDomains: [String]? = nil, diagnosticLevel: UInt = 0) {
        self.dsn = dsn
        self.debug = debug
        self.tracesSampleRate = tracesSampleRate
        self.profilesSampleRate = profilesSampleRate
        self.appHangTimeoutInterval = appHangTimeoutInterval
        self.enableAppHangTracking = enableAppHangTracking
        self.shouldCaptureHttpRequests = shouldCaptureHttpRequests
        self.httpCodesRange = httpCodesRange
        self.handledDomains = handledDomains
        self.diagnosticLevel = diagnosticLevel
    }
}
