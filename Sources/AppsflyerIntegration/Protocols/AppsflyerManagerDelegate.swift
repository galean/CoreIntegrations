
import Foundation

public protocol AppsflyerManagerDelegate {
    func coreConfiguration(didReceive deepLinkResult: [AnyHashable : Any])
    func coreConfiguration(handleDeeplinkError error: Error)
}
