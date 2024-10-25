
import Foundation

public protocol AttributionServerManagerProtocol {
    static var shared: AttributionServerManager { get }
    var userToken: String { get }
    var installResultData: AttributionManagerResult? { get }

    func configure(config: AttributionConfigData)
    func configureURLs(config: AttributionConfigURLs)
    func syncOnAppStart(_ completion: @escaping (AttributionManagerResult?) -> Void)
    func syncPurchase(data: AttributionPurchaseModel)
}
