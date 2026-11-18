
import Foundation
import StoreKit

@MainActor
public protocol PurchasesManagerProtocol {
    static var shared: PurchasesManagerProtocol { get }
    func initialize(allIdentifiers: [String], proIdentifiers: [String])
    func setUserID(_ id: String)
    func requestProducts(_ identifiers: [String]) async -> SKProductsResult
    func requestAllProducts(_ identifiers: [String]) async -> SKProductsResult
    func updateProductStatus() async
    func listenForPendingPurchases(_ result: @escaping (Transaction?, (any Error)?) -> Void)
    func purchase(_ product: Product, activeController: UIViewController?) async throws -> SKPurchaseResult
    func purchase(_ product: Product, promoOffer:SKPromoOffer, activeController: UIViewController?) async throws -> SKPurchaseResult
    func purchase(_ product: Product, options: SKPurchaseOptions, activeController: UIViewController?) async throws -> SKPurchaseResult
    func purchase(_ product: Product, promoOffer:SKPromoOffer, options: SKPurchaseOptions, activeController: UIViewController?) async throws -> SKPurchaseResult
    func restore() async -> SKRestoreResult
    func restoreAll() async -> SKRestoreResult
    func verifyPremium() async -> SKVerifyPremiumResult
    func verifyAll() async -> SKVerifyAllResult
}
