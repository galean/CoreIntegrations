
import Foundation

public protocol AttributionServerDataSource {
    associatedtype AttributionEndpoints: AttributionServerEndpointsProtocol
}

extension AttributionServerDataSource {
    var installPath: String {
        return AttributionEndpoints.install_server_path.rawValue
    }
    var purchasePath: String {
        return AttributionEndpoints.purchase_server_path.rawValue
    }
}
