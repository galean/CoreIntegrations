
import Foundation
#if !COCOAPODS
import AppsflyerIntegration
#endif

extension CoreManager: AppsflyerManagerDelegate {
    public func coreConfiguration(didReceive deepLinkResult: [AnyHashable : Any]) {
        delegate?.coreConfiguration(didReceive: deepLinkResult)
    }

    public func coreConfiguration(handleDeeplinkError error: Error) {
        delegate?.coreConfiguration(handleDeeplinkError: error)
        InternalConfigurationEvent.appsflyerWeb2AppHandled.markAsCompleted(error: error)
    }

    public func appsflyerSessionStartAttemptFailed(_ error: Error, attempt: AppsFlyerStartAttempt) {
        sendAppsflyerStartFailed(error: error, attempt: attempt)
    }

    public func appsflyerSessionStartFailed(_ error: Error, shouldReport: Bool) {
        /*
         The domain doubles as the Sentry inbound filter handle, so keep it stable and do not
         rename it: `capture(error:)` maps the domain to `exception.type`, and an inbound
         filter matches `{exception.type}: {exception.value}`. A single glob in project
         settings - `*Appsflyer_session_start_error*` - therefore kills this event server side
         with no app release, and filtered events do not consume Sentry quota.

         Worth having because the failure is entirely outside our control: if `start` ever
         breaks on the AppsFlyer side, every user reports it at once. The original SDK error
         stays attached as the underlying error, so nothing is lost in the report.
         */
        let reportedError = NSError(domain: "Appsflyer_session_start_error",
                                   code: 1002,
                                   userInfo: [NSUnderlyingErrorKey: error as NSError,
                                              NSDebugDescriptionErrorKey: error.localizedDescription])
        if shouldReport {
            sentryManager.log(reportedError)
        }
    }
    
    public func handledDeeplink(_ result: [String : String]) {
//        sendDeepLinkUserProperties(deepLinkResult: result)
        handlePossibleAttributionUpdate()
        InternalConfigurationEvent.appsflyerWeb2AppHandled.markAsCompleted()
    }
}
