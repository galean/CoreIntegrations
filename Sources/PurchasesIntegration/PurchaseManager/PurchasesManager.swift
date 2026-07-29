import StoreKit
import Foundation
import LoggingIntegration

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
    @MainActor public var purchasedConsumables: [Product] = []
    @MainActor public var purchasedNonConsumables: [Product] = []
    @MainActor public var purchasedSubscriptions: [Product] = []
    @MainActor public var purchasedNonRenewables: [Product] = []
    @MainActor public var purchasedAllProducts: [Product] = []
    
    var allIdentifiers: [String] = []
    var proIdentifiers: [String] = []
    
    var purchasePendingCallback: ((Transaction?, Error?) -> Void)?
    
    // MARK: Lifecycle
    public func initialize(allIdentifiers: [String], proIdentifiers: [String]) {
        DebugLogger.log("🏦 initialize ⚈ ⚈ ⚈ Initializing... ⚈ ⚈ ⚈")
        DebugLogger.log("🏦 initialize ⚈ ⚈ ⚈ Starting Transaction Listener... ⚈ ⚈ ⚈")
        self.allIdentifiers = allIdentifiers
        self.proIdentifiers = proIdentifiers
        
        updateListenerTask = listenForTransactions()

        Task { [weak self] in
            guard let self = self else { return }
            DebugLogger.log("🏦 initialize ⚈ ⚈ ⚈ Requesting products... ⚈ ⚈ ⚈")
            
            let _ = await self.requestAllProducts(allIdentifiers)

            DebugLogger.log("🏦 initialize ⚈ ⚈ ⚈ Updating customer product status... ⚈ ⚈ ⚈")
            
            await self.updateProductStatus()
        }
        DebugLogger.log("🏦 initialize ✅ initialized")
    }

    deinit {
        DebugLogger.log("🏦 deinit ⚈ ⚈ ⚈ Deinitializing... ⚈ ⚈ ⚈")
        updateListenerTask?.cancel()
        DebugLogger.log("🏦 deinit ✅ Deinitialized")
    }
    
    public func setUserID(_ id: String) {
        self.userId = id
    }
    
}


