
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
        configurationAttempt?.complete(InternalConfigurationEvent.appsflyerWeb2AppHandled, error: error)
    }

    public func handledDeeplink(_ result: [String : String]) {
//        sendDeepLinkUserProperties(deepLinkResult: result)
        handlePossibleAttributionUpdate()
        // A success is a fact of the process: a later attempt does not start a new session to get it again.
        recordProcessEvent(InternalConfigurationEvent.appsflyerWeb2AppHandled, error: nil)
    }
}
