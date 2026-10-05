
import Foundation

public protocol CoreManagerDelegate: AnyObject {
    func coreInitialConfigurationFinished()
    func coreInitialRemoteConfigurationFinished()
    
    func coreConfigurationFinished(result: CoreManagerResult)
    /// Called on the main thread: the remote config update completion that triggers it is
    /// delivered through the configuration manager's hop to main.
    func coreConfigurationUpdated()
    
    func coreConfiguration(didReceive deepLinkResult: [AnyHashable : Any])
    func coreConfiguration(handleDeeplinkError error: Error)
    func coreConfiguration(fcmTokenUpdated token: String)
}

public extension CoreManagerDelegate {
    func coreConfiguration(didReceive deepLinkResult: [AnyHashable : Any]) {
        
    }
}
