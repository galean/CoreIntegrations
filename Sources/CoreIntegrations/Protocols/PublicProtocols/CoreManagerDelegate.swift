
import Foundation

public protocol CoreManagerDelegate: AnyObject {
    func coreInitialConfigurationFinished()
    func coreInitialRemoteConfigurationFinished()
    
    /// Called on the main thread. `.finished` is the terminal result of a configuration attempt and is
    /// delivered once per attempt. `.noInternet` (China region, first launch, both backend requests failed)
    /// is not terminal: the framework retries once, automatically, when the app is active and the network
    /// is available, and then delivers `.finished` for that retry. So after `.noInternet` the delegate can
    /// receive this callback a second time; without network it receives nothing until the network appears.
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
