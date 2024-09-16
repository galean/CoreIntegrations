
import Foundation

public struct AttributionPurchaseModel: Codable {
    let price: CGFloat
    let introductoryPrice: CGFloat?
    let currencyCode: String
    let subscriptionIdentifier: String
    let jws: String?
    let originalTransactionID: String?
    let decodedTransaction: Data?
    
    public init(price: CGFloat, introductoryPrice: CGFloat?,
                currencyCode: String, subscriptionIdentifier: String,
                jws: String?, originalTransactionID: String?, decodedTransaction: Data?) {
        self.price = price
        self.introductoryPrice = introductoryPrice
        self.currencyCode = currencyCode
        self.subscriptionIdentifier = subscriptionIdentifier
        self.jws = jws
        self.originalTransactionID = originalTransactionID
        self.decodedTransaction = decodedTransaction
    }
}
