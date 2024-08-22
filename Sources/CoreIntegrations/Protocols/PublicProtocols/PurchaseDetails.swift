
import Foundation
import StoreKit

public struct PurchaseDetails {
    public let productId: String
    public let product: Product
    public let transaction: Transaction
    public let jws: String?
    public let originalTransactionID: String?
    public let decodedTransaction: Data?
    
    
    public init(productId: String, product: Product, transaction: Transaction, jws: String?, originalTransactionID: String?, decodedTransaction: Data?) {
        self.productId = productId
        self.product = product
        self.transaction = transaction
        self.jws = jws
        self.originalTransactionID = originalTransactionID
        self.decodedTransaction = decodedTransaction
    }
}
