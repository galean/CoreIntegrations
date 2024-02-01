import Foundation
import StoreKit

public typealias Transaction = StoreKit.Transaction
public typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
public typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

struct DebuggingIdentifiers {
    static let actionOrEventSucceded: String = "✅"
    static let actionOrEventInProgress: String = "⚈ ⚈ ⚈"
    static let actionOrEventFailed: String = "❌"
    static let notificationSent: String = "📤"
    static let notificationRecieved: String = "📥"
}


public class StoreKitCoordinator: NSObject {

    // MARK: Variables
    static let identifier: String = "[StoreKitCoordinator]"
    static public let shared: StoreKitCoordinator = StoreKitCoordinator()
    // A transaction listener to listen to transactions on init and through out the apps use.
    private var updateListenerTask: Task<Void, Error>?

    // MARK: Offering Arrays
    // Arrays are initially empty and are filled in when we gather the products
    public var consumables: [Product] = []
    public var nonConsumables: [Product] = []
    public var subscriptions: [Product] = []
    public var nonRenewables: [Product] = []
    // Arrays that hold the purchases products
    public var purchasedConsumables: [Product] = []
    public var purchasedNonConsumables: [Product] = []
    public var purchasedSubscriptions: [Product] = []
    public var purchasedNonRenewables: [Product] = []
    // A variable to hold the Subscription Group Renewal State, if you have more than one subscription group, you will need more than one.
    public var subscriptionGroupStatus: RenewalState?
    
    // MARK: Lifecycle
    public func initialize(identifiers: [String]) {
        debugPrint("\(StoreKitCoordinator.identifier) initialize \(DebuggingIdentifiers.actionOrEventInProgress) Initializing... \(DebuggingIdentifiers.actionOrEventInProgress)")
        // Start a transaction listener as close to app launch as possible so you don't miss any transactions.
        debugPrint("\(StoreKitCoordinator.identifier) initialize \(DebuggingIdentifiers.actionOrEventInProgress) Starting Transaction Listener... \(DebuggingIdentifiers.actionOrEventInProgress)")
        updateListenerTask = listenForTransactions()

        Task { [weak self] in
            guard let self = self else { return }
            // During store initialization, request products from the App Store.
            debugPrint("\(StoreKitCoordinator.identifier) initialize \(DebuggingIdentifiers.actionOrEventInProgress) Requesting products... \(DebuggingIdentifiers.actionOrEventInProgress)")
            let result = await self.requestProducts(identifiers)

            // Deliver products that the customer purchases.
            debugPrint("\(StoreKitCoordinator.identifier) initialize \(DebuggingIdentifiers.actionOrEventInProgress) Updating customer product status... \(DebuggingIdentifiers.actionOrEventInProgress)")
            await self.updateCustomerProductStatus()
        }
        debugPrint("\(StoreKitCoordinator.identifier) initialize \(DebuggingIdentifiers.actionOrEventSucceded) initialized")
    }

    deinit {
        debugPrint("\(StoreKitCoordinator.identifier) deinit \(DebuggingIdentifiers.actionOrEventInProgress) Deinitializing... \(DebuggingIdentifiers.actionOrEventInProgress)")
        // Deinitialize configuration
        updateListenerTask?.cancel()
        debugPrint("\(StoreKitCoordinator.identifier) deinit \(DebuggingIdentifiers.actionOrEventSucceded) Deinitialized")
    }

}

