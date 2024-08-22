
import Foundation

internal protocol AttributionUserDefaultsWorkerProtocol {
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
}
