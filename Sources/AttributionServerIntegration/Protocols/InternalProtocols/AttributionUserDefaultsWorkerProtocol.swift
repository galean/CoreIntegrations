import Foundation

internal protocol AttributionUserDefaultsWorkerProtocol {
    var uuid: String { get }
    
    func getInstallData() -> AttributionInstallRequestModel?
    func saveInstallData(_ data: AttributionInstallRequestModel)
    func deleteSavedInstallData()
    
    func saveInstallResult(_ result: AttributionManagerResult?)
    func getInstallResult() -> AttributionManagerResult?

    func getGeneratedToken() -> String?
    func saveGeneratedToken(_ token: String)

    func getPurchaseData() -> AttributionPurchaseModel?
    func savePurchaseData(_ data: AttributionPurchaseModel)
    func deleteSavedPurchaseData()

    func getServerUserID() -> AttributionUserUUID?
    func saveServerUserID(_ id: AttributionUserUUID)

    func getAppTransactionSent() -> Bool
    func saveAppTransactionSent(_ sent: Bool)
    
    func getFCMToken() -> String?
    func saveFCMToken(_ token: String)

    func getExternalAuthData() -> String?
    func saveExternalAuthData(_ externalAuthId: String)
    func deleteSavedExternalAuthData()
    
    func getConsentData() -> AttributionConsentFields?
    func saveConsentData(_ data: AttributionConsentFields)
    func deleteSavedConsentData()
}
