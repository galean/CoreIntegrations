
import Foundation

public protocol AppsflyerManagerDelegate {
    func handledDeeplink(_ result: [String: String])
    
    func coreConfiguration(didReceive deepLinkResult: [AnyHashable : Any])
    func coreConfiguration(handleDeeplinkError error: Error)

    /// Called when the SDK failed to send the session. Without this a failed start is
    /// invisible: the SDK reports nothing and every install silently disappears. Not called
    /// for a rate limited start - see `appsflyerSessionStartAttemptFailed(_:attempt:)`.
    ///
    /// - Parameter shouldReport: `true` only for the first failure on an install where the
    ///   SDK has never started successfully. Crash/error reporting has to be skipped when
    ///   this is `false` - an outage on the AppsFlyer side would otherwise have every user
    ///   reporting on every launch.
    func appsflyerSessionStartFailed(_ error: Error, shouldReport: Bool)

    /// Called for every `start()` completion with an error, rate limited ones included.
    /// The error is not final for the session: the SDK re-sends a cached launch with the next
    /// `start()` or event.
    func appsflyerSessionStartAttemptFailed(_ error: Error, attempt: AppsFlyerStartAttempt)
}

public extension AppsflyerManagerDelegate {
    func appsflyerSessionStartFailed(_ error: Error, shouldReport: Bool) {}
}
