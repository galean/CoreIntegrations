
import Foundation

public protocol CoreManagerDelegate: AnyObject {
    func coreConfigurationFinished()
    
    func coreConfiguration(didReceive deepLinkResult: [AnyHashable : Any])
    func coreConfiguration(handleDeeplinkError error: Error)
}

public extension CoreManagerDelegate {
    func coreConfiguration(didReceive deepLinkResult: [AnyHashable : Any]) {
        
    }
}
