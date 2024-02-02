import StoreKit
import Foundation

//temporary object from swifty kit
public struct PurchaseDetails {
    public let productId: String
    public let quantity: Int
    public let product: Product
    public let transaction: Transaction
    public let needsFinishTransaction: Bool
    
    public init(productId: String, quantity: Int, product: Product, transaction: Transaction, needsFinishTransaction: Bool) {
        self.productId = productId
        self.quantity = quantity
        self.product = product
        self.transaction = transaction
        self.needsFinishTransaction = needsFinishTransaction
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
    
    public func restore() async -> Bool {
        return await StoreKitCoordinator.shared.restore()
    }
    
}
