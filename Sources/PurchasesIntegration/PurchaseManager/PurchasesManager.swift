import StoreKit
import Foundation

public typealias Transaction = StoreKit.Transaction
public typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
public typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

public class PurchasesManager: NSObject, PurchasesManagerProtocol {
    // MARK: Variables
    static let identifier: String = "🏦"
    static public let shared: PurchasesManagerProtocol = internalShared
    public var userId: String = ""
    static var internalShared = PurchasesManager()
    // A transaction listener to listen to transactions on init and through out the apps use.
    private var updateListenerTask: Task<Void, Error>?

    // MARK: Offering Arrays
    // Arrays are initially empty and are filled in when we gather the products
    var allAvailableProducts: [Product] = []
    public var consumables: [Product] = []
    public var nonConsumables: [Product] = []
    public var subscriptions: [Product] = []
    public var nonRenewables: [Product] = []
    // Arrays that hold the purchases products
    public var purchasedConsumables: [Product] = []
    public var purchasedNonConsumables: [Product] = []
    public var purchasedSubscriptions: [Product] = []
    public var purchasedNonRenewables: [Product] = []
    
    // MARK: Lifecycle
    public func initialize(identifiers: [String]) {
        debugPrint("🏦 initialize ⚈ ⚈ ⚈ Initializing... ⚈ ⚈ ⚈")
        debugPrint("🏦 initialize ⚈ ⚈ ⚈ Starting Transaction Listener... ⚈ ⚈ ⚈")
        
        updateListenerTask = listenForTransactions()

        Task { [weak self] in
            guard let self = self else { return }
            debugPrint("🏦 initialize ⚈ ⚈ ⚈ Requesting products... ⚈ ⚈ ⚈")
            
            let _ = await self.requestAllProducts(identifiers)

            debugPrint("🏦 initialize ⚈ ⚈ ⚈ Updating customer product status... ⚈ ⚈ ⚈")
            
            await self.updateProductStatus()
        }
        debugPrint("🏦 initialize ✅ initialized")
    }

    deinit {
        debugPrint("🏦 deinit ⚈ ⚈ ⚈ Deinitializing... ⚈ ⚈ ⚈")
        updateListenerTask?.cancel()
        debugPrint("🏦 deinit ✅ Deinitialized")
    }
    
    public func setUserID(_ id: String) {
        self.userId = id
    }
    
}

public protocol PurchasesManagerProtocol {
    static var shared: PurchasesManagerProtocol { get }

    func initialize(identifiers: [String])
    func setUserID(_ id: String)
    func requestProducts(_ identifiers: [String]) async -> SKProductsResult
    func requestAllProducts(_ identifiers: [String]) async -> SKProductsResult
    func updateProductStatus() async
    func purchase(_ product: Product) async throws -> SKPurchaseResult
    func restore() async -> SKRestoreResult 
    func verifyPremium() async -> PurchasesVerifyPremiumResult
}
