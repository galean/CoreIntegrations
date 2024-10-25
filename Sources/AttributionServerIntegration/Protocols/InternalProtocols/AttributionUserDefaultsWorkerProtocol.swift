
import Foundation

internal protocol AttributionUserDefaultsWorkerProtocol {
    func getInstallData() -> AttributionInstallRequestModel?
    func saveInstallData(_ data: AttributionInstallRequestModel)
    func deleteSavedInstallData()
    
    func getUserToken() -> String?
    func saveUserToken(_ token: String)
    
    func saveInstallResult(_ result: AttributionManagerResult?)
    func getInstallResult() -> AttributionManagerResult?

    func getPurchaseData() -> AttributionPurchaseModel?
    func savePurchaseData(_ data: AttributionPurchaseModel)
    func deleteSavedPurchaseData()

    func getServerUserID() -> AttributionUserUUID?
    func saveServerUserID(_ id: AttributionUserUUID)
}
