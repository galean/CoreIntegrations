
import Foundation

public struct SentryConfigData {
    let dsn: String
    let debug: Bool
    var enableLogs: Bool
    var tracesSampleRate: Float
//    var profilesSampleRate: Float
    var appHangTimeoutInterval: TimeInterval
    var enableAppHangTracking: Bool
    var shouldCaptureHttpRequests: Bool
    var httpCodesRange: NSRange
    let handledDomains: [String]?
    var diagnosticLevel: UInt
    var swizzleClassNameExcludes: Set<String>
    var enableMetricKit: Bool

    public init(
        dsn: String,
        debug: Bool,
        enableLogs: Bool = false,
        tracesSampleRate: Float = 1.0,
        //  profilesSampleRate: Float = 1.0,
        appHangTimeoutInterval: TimeInterval = 2.0,
        enableAppHangTracking: Bool = true,
        shouldCaptureHttpRequests: Bool = true,
        httpCodesRange: NSRange = NSMakeRange(202, 599),
        handledDomains: [String]? = nil,
        diagnosticLevel: UInt = 0,
        swizzleClassNameExcludes: Set<String> = [],
        enableMetricKit: Bool = false
    ) {
        self.dsn = dsn
        self.debug = debug
        self.tracesSampleRate = tracesSampleRate
//        self.profilesSampleRate = profilesSampleRate
        self.appHangTimeoutInterval = appHangTimeoutInterval
        self.enableAppHangTracking = enableAppHangTracking
        self.shouldCaptureHttpRequests = shouldCaptureHttpRequests
        self.httpCodesRange = httpCodesRange
        self.handledDomains = handledDomains
        self.diagnosticLevel = diagnosticLevel
        self.enableLogs = enableLogs
        self.swizzleClassNameExcludes = swizzleClassNameExcludes
        self.enableMetricKit = enableMetricKit
    }
}
