
import Foundation

public protocol AttributionServerManagerProtocol {
    static var shared: AttributionServerManager { get }
    var uniqueUserID: String? { get }
    var savedUserUUID: String? { get }
    var installResultData: AttributionManagerResult? { get }
    var installError: Error? { get }

    func configure(config: AttributionConfigData)
    func configureURLs(config: AttributionConfigURLs)
    func syncOnAppStart(_ completion: @escaping (AttributionManagerResult?) -> Void)
    func syncPurchase(data: AttributionPurchaseModel)
}
