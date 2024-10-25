
import Foundation

internal struct AttrubutionPurchaseRequestModel: Codable {
    let productId: String
    let purchaseId: String
    let userId: String
    let adid: String
    let version: Int
    let signedTransaction: String?
    let decodedTransaction: Data?
    let originalTransactionID: String?
    let paymentDetails: PaymentDetails
    
    struct PaymentDetails: Codable {
        let price: CGFloat
        let introductoryPrice: CGFloat
        let currency: String
    }
}
