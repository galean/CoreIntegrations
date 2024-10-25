
import Foundation

public struct AttributionManagerResult: Codable {
    public let userUUID: AttributionUserUUID
    public let asaAttribution: [String: String]
    public let isIPAT: Bool
}
