
import Foundation

internal protocol AttributionServerWorkerProtocol {
    func sendInstallAnalytics(parameters: AttributionInstallRequestModel, authToken: AttributionServerToken,
                              completion: @escaping (([String: String]?) -> Void))
    func sendPurchaseAnalytics(analytics: AttrubutionPurchaseRequestModel,
                               userId: AttributionUserUUID,
                               authToken: AttributionServerToken,
                               completion: @escaping ((Bool) -> Void))
}
