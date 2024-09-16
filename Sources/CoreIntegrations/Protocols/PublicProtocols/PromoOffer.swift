
import Foundation

public struct PromoOffer {
    let offerID: String
    let keyID: String
    let nonce: UUID
    let signature: Data
    let timestamp: Int
}
