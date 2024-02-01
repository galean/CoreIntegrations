import StoreKit
import Foundation

//temporary object from swifty kit
public struct PurchaseDetails {
    public let productId: String
    public let quantity: Int
    public let product: SKProduct
    public let transaction: Transaction
    public let originalTransaction: Transaction?
    public let needsFinishTransaction: Bool
    
    public init(productId: String, quantity: Int, product: SKProduct, transaction: Transaction, originalTransaction: Transaction?, needsFinishTransaction: Bool) {
        self.productId = productId
        self.quantity = quantity
        self.product = product
        self.transaction = transaction
        self.originalTransaction = originalTransaction
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

    public func purchase(_ product: Product) async -> SKPurchaseResult? {
        let result = try? await StoreKitCoordinator.shared.purchase(product)
        return result
    }
    
    public func verifyPremium() async -> Bool {
        return await StoreKitCoordinator.shared.verifyPremium()
    }
    
    public func restore() async -> Bool {
        return await StoreKitCoordinator.shared.restore()
    }
    
}
