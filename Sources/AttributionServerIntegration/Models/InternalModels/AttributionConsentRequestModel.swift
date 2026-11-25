import Foundation

internal struct AttributionConsentRequestModel: Codable {
    let appsflyerId: String
    let consent: AttributionConsentFields
}
