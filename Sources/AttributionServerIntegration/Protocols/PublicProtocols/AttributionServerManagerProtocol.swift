
import Foundation

public protocol AttributionServerManagerProtocol {
    static var shared: AttributionServerManager { get }
    var uniqueUserID: String? { get }
    var savedUserUUID: String? { get }
    var fcmToken: String? { get }
    var installResultData: AttributionManagerResult? { get }
    var installError: Error? { get }

    func configure(config: AttributionConfigData)
    func configureURLs(config: AttributionConfigURLs)
    /// Completes at most once (never without an authorization token): with the server result (`nil` on failure) for a new install, or on main with the
    /// saved result for an install that is already registered (`nil` for legacy data without one).
    func syncOnAppStart(_ completion: @escaping (AttributionManagerResult?) -> Void)
    func sendExternalAuthorization(externalAuthID: String)
    func syncPurchase(data: AttributionPurchaseModel)
}
