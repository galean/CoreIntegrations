
import Foundation

internal protocol AttributionDataWorkerProtocol {
    var idfa: String? { get }
    var idfv: String? { get }
    var uuid: String { get }
    var sdkVersion: String { get }
    var osVersion: String { get }
    var appVersion: String { get }
    var isAdTrackingEnabled: Bool { get }
    func attributionDetails() async throws -> [String: Any]?
    var storeCountry: String { get }
    
    var receiptToken: String { get }
    
    func generateUniqueToken() -> String
}
