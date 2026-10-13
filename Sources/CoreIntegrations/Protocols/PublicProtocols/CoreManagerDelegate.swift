
import Foundation

public protocol CoreManagerDelegate: AnyObject {
    func coreInitialConfigurationFinished()
    /// Called on main.
    func coreInitialRemoteConfigurationFinished()
    
    /// Called on main. `.noInternet` (China, first launch, both backend requests failed) is not final:
    /// the framework retries once, when the app becomes active again or the network appears, and then
    /// calls this with `.finished` within the configuration timeout, with or without network.
    func coreConfigurationFinished(result: CoreManagerResult)
    /// Called on main.
    func coreConfigurationUpdated()
    
    func coreConfiguration(didReceive deepLinkResult: [AnyHashable : Any])
    func coreConfiguration(handleDeeplinkError error: Error)
    func coreConfiguration(fcmTokenUpdated token: String)
}

public extension CoreManagerDelegate {
    func coreConfiguration(didReceive deepLinkResult: [AnyHashable : Any]) {
        
    }
}
