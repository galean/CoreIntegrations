
import Foundation

public protocol AttributionServerDataSource {
    associatedtype AttributionEndpoints: AttributionServerEndpointsProtocol
    
    var isRemoteConfigurable: Bool { get }
}

extension AttributionServerDataSource {
    var installPath: String {
        return AttributionEndpoints.install_server_path.rawValue
    }
    var purchasePath: String {
        return AttributionEndpoints.purchase_server_path.rawValue
    }
}
