
import Foundation

internal protocol AttributionServerWorkerProtocol {
    func sendInstallAnalytics(parameters: AttributionInstallRequestModel, authToken: AttributionServerToken,
                              isBackgroundSession: Bool,
                              completion: @escaping (([String: String]?, Error?) -> Void))
    func sendPurchaseAnalytics(analytics: AttrubutionPurchaseRequestModel,
                               userId: AttributionUserUUID,
                               authToken: AttributionServerToken,
                               isBackgroundSession: Bool,
                               completion: @escaping ((Bool) -> Void))
}
