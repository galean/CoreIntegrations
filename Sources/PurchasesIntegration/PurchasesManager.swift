import StoreKit
import Foundation

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

public class PurchasesManager {
    private var subscriptionSecret: String
    
    public required init(subscriptionSecret: String) {
        self.subscriptionSecret = subscriptionSecret
    }
}

extension PurchasesManager: PurchasesManagerProtocol {

    public func purchase(_ product: Product) async throws -> SKPurchaseResult {
        let result = try await StoreKitCoordinator.shared.purchase(product)
        return result
    }
    
    public func verifyPremium() async -> PurchasesVerifyPremiumResult {
        return await StoreKitCoordinator.shared.verifyPremium()
    }
    
    public func restore() async -> SKRestoreResult {
        return await StoreKitCoordinator.shared.restore()
    }
    
}
