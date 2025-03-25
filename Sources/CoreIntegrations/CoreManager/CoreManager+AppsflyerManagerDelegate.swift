
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
        InternalConfigurationEvent.appsflyerWeb2AppHandled.markAsCompleted()
    }
    
    public func handledDeeplink(_ result: [String : String]) {
//        sendDeepLinkUserProperties(deepLinkResult: result)
        handlePossibleAttributionUpdate()
        InternalConfigurationEvent.appsflyerWeb2AppHandled.markAsCompleted()
    }
}
