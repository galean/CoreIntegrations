
import Foundation
import StoreKit
import LoggingIntegration

extension PurchasesManager {
    
    struct EntitlementSnapshot {
        var consumables: [Product] = []
        var nonConsumables: [Product] = []
        var nonRenewables: [Product] = []
        var subscriptions: [Product] = []
        var allProducts: [Product] = []
    }
    

    func grantsEntitlement(_ state: RenewalState) -> Bool {
        state == .subscribed || state == .inGracePeriod
    }

    public func updateAllProductsStatus() async -> [Product] {
        var purchasedAllProducts: [Product] = []
        
        for await result in Transaction.all {
            do {
                let transaction = try checkVerified(result)
                
                switch transaction.productType {
                case .consumable:
                    if let consumable = consumables.first(where: { $0.id == transaction.productID }) {
                        purchasedAllProducts.append(consumable)
                    }
                case .nonConsumable:
                    if let nonConsumable = nonConsumables.first(where: { $0.id == transaction.productID }) {
                        purchasedAllProducts.append(nonConsumable)
                    }
                case .nonRenewable:
                    if let nonRenewable = nonRenewables.first(where: { $0.id == transaction.productID }) {
                        purchasedAllProducts.append(nonRenewable)
                    }
                case .autoRenewable:
                    if subscriptions.isEmpty {
                        let _ =  await requestAllProducts(self.allIdentifiers)
                    }
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedAllProducts.append(subscription)
                    }
                default:
                    DebugLogger.log("🏦 updateAllProductsStatus ❌ Hit default \(transaction.productID).")
                    break
                }
            } catch {
                DebugLogger.log("🏦 updateAllProductsStatus ❌ failed to grant product access \(result.debugDescription).")
            }
        }
        DebugLogger.log("🏦 updateAllProductsStatus ✅ array \(purchasedAllProducts).")
        return purchasedAllProducts
    }
    
    @MainActor
    public func updateProductStatus() async {
        DebugLogger.log("🏦 updateProductStatus ⚈ ⚈ ⚈ Updating Customer Product Status... ⚈ ⚈ ⚈")
        var snapshot = EntitlementSnapshot()

        for await result in Transaction.currentEntitlements {
            do {
                DebugLogger.log("🏦 updateProductStatus ⚈ ⚈ ⚈ Checking verification for product \(result.debugDescription)... ⚈ ⚈ ⚈")
                let transaction = try checkVerified(result)
                await classify(transaction, into: &snapshot)
            } catch {
                DebugLogger.log("🏦 updateProductStatus ❌ failed to grant product access \(result.debugDescription).")
            }
        }
        DebugLogger.log("🏦 updateProductStatus ⚈ ⚈ ⚈ Updating Purchased Arrays... ⚈ ⚈ ⚈")

        self.purchasedConsumables = snapshot.consumables
        self.purchasedNonConsumables = snapshot.nonConsumables
        self.purchasedNonRenewables = snapshot.nonRenewables
        self.purchasedSubscriptions = snapshot.subscriptions
        self.purchasedAllProducts = snapshot.allProducts

        DebugLogger.log("🏦 updateProductStatus ✅ Updated Purchased arrays.")
    }

    private func classify(_ transaction: Transaction, into snapshot: inout EntitlementSnapshot) async {
        switch transaction.productType {
        case .consumable:
            handleConsumable(transaction, into: &snapshot)
        case .nonConsumable:
            handleNonConsumable(transaction, into: &snapshot)
        case .nonRenewable:
            handleNonRenewable(transaction, into: &snapshot)
        case .autoRenewable:
            await handleAutoRenewable(transaction, into: &snapshot)
        default:
            DebugLogger.log("🏦 updateProductStatus ❌ Hit default \(transaction.productID).")
        }
    }

    private func handleConsumable(_ transaction: Transaction, into snapshot: inout EntitlementSnapshot) {
        if let consumable = consumables.first(where: { $0.id == transaction.productID }) {
            snapshot.consumables.append(consumable)
            snapshot.allProducts.append(consumable)
            DebugLogger.log("🏦 updateProductStatus ✅ Consumable added to purchased Consumables.")
        } else {
            DebugLogger.log("🏦 updateProductStatus ❌ Consumable Product Id not within the offering : \(transaction.productID).")
        }
    }

    private func handleNonConsumable(_ transaction: Transaction, into snapshot: inout EntitlementSnapshot) {
        if let nonConsumable = nonConsumables.first(where: { $0.id == transaction.productID }) {
            snapshot.nonConsumables.append(nonConsumable)
            snapshot.allProducts.append(nonConsumable)
            DebugLogger.log("🏦 updateProductStatus ✅ Non-Consumable added to purchased Non-Consumables \(transaction.productID).")
        } else {
            DebugLogger.log("🏦 updateProductStatus ❌ Non-Consumable Product Id not within the offering : \(transaction.productID).")
        }
    }

    private func handleNonRenewable(_ transaction: Transaction, into snapshot: inout EntitlementSnapshot) {
        guard let nonRenewable = nonRenewables.first(where: { $0.id == transaction.productID }) else {
            DebugLogger.log("🏦 updateProductStatus ❌ Non-Renewing Subscription Product Id not within the offering : \(transaction.productID).")
            return
        }
        snapshot.allProducts.append(nonRenewable)

        let currentDate = Date()
        let expirationDate = Calendar(identifier: .gregorian).date(byAdding: DateComponents(year: 1), to: transaction.purchaseDate)!

        if currentDate < expirationDate {
            snapshot.nonRenewables.append(nonRenewable)
            DebugLogger.log("🏦 updateProductStatus ✅ Non-Renewing Subscription added to purchased non-renewing subscriptions.")
        } else {
            DebugLogger.log("🏦 updateProductStatus ❌ Non-Renewing Subscription with Id  \(transaction.productID) expired.")
        }
    }

    private func handleAutoRenewable(_ transaction: Transaction, into snapshot: inout EntitlementSnapshot) async {
        if subscriptions.isEmpty {
            let _ = await requestAllProducts(self.allIdentifiers)
        }
        
        guard let subscription = subscriptions.first(where: { $0.id == transaction.productID }) else {
            if subscriptions.isEmpty {
                DebugLogger.log("🏦 updateProductStatus ❌ Auto-Renewable Subscriptons array is empty.")
            }
            subscriptions.forEach { product in
                DebugLogger.log("🏦 updateProductStatus ❌ Auto-Renewable Subscripton Array product: \(product.id).")
            }
            DebugLogger.log("🏦 updateProductStatus ❌ Auto-Renewable Subscripton Product Id not within the offering : \(transaction.productID).")
            return
        }
        
        snapshot.allProducts.append(subscription)

        let status = await transaction.subscriptionStatus
        if let state = status?.state {
            if grantsEntitlement(state) {
                snapshot.subscriptions.append(subscription)
            }
            
            logRenewalState(state, productID: transaction.productID)
        }
        
        DebugLogger.log("🏦 updateProductStatus ✅ Transaction purchaseDate \(transaction.purchaseDate), Transaction expirationDate \(String(describing: transaction.expirationDate))")
    }

    private func logRenewalState(_ state: RenewalState, productID: String) {
        switch state {
        case .subscribed:
            DebugLogger.log("🏦 updateProductStatus ✅ Auto-Renewable Subscription added to purchased auto-renewable subscriptions \(productID).")
        case .inGracePeriod:
            DebugLogger.log("🏦 updateProductStatus ⚠️ Auto-Renewable Subscription \(productID) is in grace period, access granted.")
        case .inBillingRetryPeriod:
            DebugLogger.log("🏦 updateProductStatus ❌ Auto-Renewable Subscription \(productID) is in billing retry period, skip.")
        case .revoked:
            DebugLogger.log("🏦 updateProductStatus ❌ Auto-Renewable Subscription \(productID) was revoked, skip.")
        case .expired:
            DebugLogger.log("🏦 updateProductStatus ❌ Auto-Renewable Subscription \(productID) is expired, skip.")
        default:
            DebugLogger.log("🏦 updateProductStatus ❌ Auto-Renewable Subscription \(productID) hit unknown renewal state \(state), skip.")
        }
    }

    public func getSubscriptionStatus(product: Product) async -> RenewalState? {
        guard let subscription = product.subscription else {
            // Not a subscription
            return nil
        }
        do {
            DebugLogger.log("🏦 ⚈ ⚈ ⚈ getSubscriptionStatuses ⚈ ⚈ ⚈")
            let statuses = try await subscription.status
            DebugLogger.log("🏦 getSubscriptionStatuses ✅ \(statuses.count) for product \(product.id)")
            
            for status in statuses {
                DebugLogger.log("🏦 getSubscriptionStatuses ✅ status check \(status)")
                let info = try checkVerified(status.renewalInfo)
                DebugLogger.log("🏦 getSubscriptionStatuses ✅ status state \(status.state)")
                switch status.state {
                case .subscribed:
                    if info.willAutoRenew {
                        DebugLogger.log("🏦 getSubscriptionStatus user subscription is active.")
                    } else {
                        DebugLogger.log("🏦 getSubscriptionStatus user subscription is expiring.")
                    }
                case .inBillingRetryPeriod:
                    DebugLogger.log("🏦 getSubscriptionStatus user subscription is in billing retry period.")
                case .inGracePeriod:
                    DebugLogger.log("🏦 getSubscriptionStatus user subscription is in grace period.")
                case .expired:
                    DebugLogger.log("🏦 getSubscriptionStatus user subscription is expired.")
                case .revoked:
                    DebugLogger.log("🏦 getSubscriptionStatus user subscription was revoked.")
                default:
                    fatalError("🏦 getSubscriptionStatus WARNING STATE NOT CONSIDERED.")
                }
                return status.state
            }
        } catch {
            return nil
        }
        return nil
    }
}
