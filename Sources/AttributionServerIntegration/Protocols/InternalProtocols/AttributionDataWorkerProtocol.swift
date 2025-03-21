
import Foundation

internal protocol AttributionDataWorkerProtocol {
    var idfa: String? { get }
    var idfv: String? { get }
    var sdkVersion: String { get }
    var osVersion: String { get }
    var appVersion: String { get }
    var isAdTrackingEnabled: Bool { get }
    func attributionDetails() async -> AttributionDetails?
    var storeCountry: String { get }
    
    var receiptToken: String { get }
    
    func generateUniqueToken() -> String
}

struct AttributionDetails {
    var details:[String: Any]?
    var attributionToken: String
}
