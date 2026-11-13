import Foundation
import Sentry

public protocol SentryDataSourceProtocol: AnyObject {
    var dsn: String { get }
    var debug: Bool { get }
    var enableLogs: Bool { get }
    var tracesSampleRate: Float { get }
    var profilesSampleRate: Float { get }
    var shouldCaptureHttpRequests: Bool { get }
    var httpCodesRange: NSRange { get }
    var handledDomains: [String]? { get }
    var diagnosticLevel: UInt { get }
    var swizzleClassNameExcludes: Set<String> { get }
    var enableMetricKit: Bool { get }
    var enableAppHangTracking: Bool { get }
    
    /// Called for each Sentry event before it is sent: return `true` to send it, `false` to drop it.
    var shouldSendEvent: ((Sentry.Event) -> Bool)? { get }
}

public extension SentryDataSourceProtocol {
    var tracesSampleRate: Float {
        return 1.0
    }
    
    var profilesSampleRate: Float {
        return 1.0
    }
    
    var shouldCaptureHttpRequests: Bool {
        return true
    }
    
    var enableLogs: Bool {
        return false
    }
    
    var httpCodesRange: NSRange {
        return NSMakeRange(202, 599)
    }
    
    var handledDomains:[String]? {
        return nil
    }
    
    var diagnosticLevel: UInt {
        return 0
    }
    
    var swizzleClassNameExcludes: Set<String> {
        return []
    }
    
    var enableMetricKit: Bool {
        return false
    }
    
    var enableAppHangTracking: Bool {
        return true
    }
    
    var shouldSendEvent: ((Sentry.Event) -> Bool)? {
        return nil
    }
}
