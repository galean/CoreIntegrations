
import Foundation

public protocol AttributionServerEndpointsProtocol: RawRepresentable where RawValue == String {
    static var install_server_path: Self { get }
    static var purchase_server_path: Self { get }
}
