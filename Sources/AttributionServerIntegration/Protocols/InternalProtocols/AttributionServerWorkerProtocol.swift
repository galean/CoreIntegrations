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
	func sendAppTransaction(parameters: AttributionAppTransactionRequestModel,
                            authToken: AttributionServerToken,
                            isBackgroundSession: Bool,
                            completion: @escaping ((Bool) -> Void))
    func sendFCMToken(parameters: AttributionTokenRequestModel,
                      authToken: AttributionServerToken,
                      isBackgroundSession: Bool,
                      completion: @escaping ((Bool) -> Void))
    func sendExternalAuthorization(parameters: AttributionExternalAuthRequestModel,
                                   authToken: AttributionServerToken,
                                   completion: @escaping ((Bool) -> Void))
    func sendConsent(parameters: AttributionConsentRequestModel,
                     authToken: AttributionServerToken,
                     completion: @escaping ((Bool) -> Void))
}
