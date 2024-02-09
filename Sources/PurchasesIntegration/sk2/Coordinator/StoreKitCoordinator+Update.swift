import Foundation
import StoreKit

extension StoreKitCoordinator {
    public func updateCustomerProductStatus() async {
        debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventInProgress) Updating Customer Product Status... \(DebuggingIdentifiers.actionOrEventInProgress)")
        var purchasedConsumables: [Product] = []
        var purchasedNonConsumables: [Product] = []
        var purchasedSubscriptions: [Product] = []
        var purchasedNonRenewableSubscriptions: [Product] = []

        // Iterate through all of the user's purchased products.
        for await result in Transaction.currentEntitlements {
            do {
                debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventInProgress) Checking verification for product \(result.debugDescription)... \(DebuggingIdentifiers.actionOrEventInProgress)")
                // Check whether the transaction is verified. If it isn’t, catch `failedVerification` error.
                let transaction = try checkVerified(result)

                // Check the `productType` of the transaction and get the corresponding product from the store.
                switch transaction.productType {
                case .consumable:
                    if let consumable = consumables.first(where: { $0.id == transaction.productID }) {
                        purchasedConsumables.append(consumable)
                        debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventSucceded) Non-Consumable added to purchased Non-Consumables.")
                    } else {
                        debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventFailed) Non-Consumable Product Id not within the offering : \(transaction.productID).")
                    }
                case .nonConsumable:
                    if let nonConsumable = nonConsumables.first(where: { $0.id == transaction.productID }) {
                        purchasedNonConsumables.append(nonConsumable)
                        debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventSucceded) Non-Consumable added to purchased Non-Consumables.")
                    } else {
                        debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventFailed) Non-Consumable Product Id not within the offering : \(transaction.productID).")
                    }
                case .nonRenewable:
                    if let nonRenewable = nonRenewables.first(where: { $0.id == transaction.productID }) {
                        // Non-renewing subscriptions have no inherent expiration date, so they're always
                        // contained in `Transaction.currentEntitlements` after the user purchases them.
                        // This app defines this non-renewing subscription's expiration date to be one year after purchase.
                        // If the current date is within one year of the `purchaseDate`, the user is still entitled to this
                        // product.
                        let currentDate = Date()
                        let expirationDate = Calendar(identifier: .gregorian).date(byAdding: DateComponents(year: 1),
                                                                                   to: transaction.purchaseDate)!

                        if currentDate < expirationDate {
                            purchasedNonRenewableSubscriptions.append(nonRenewable)
                            debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventSucceded) Non-Renewing Subscription added to purchased non-renewing subscriptions.")
                        } else {
                            debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventFailed) Non-Renewing Subscription with Id  \(transaction.productID) expired.")
                        }
                    } else {
                        debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventFailed) Non-Renewing Subscription Product Id not within the offering : \(transaction.productID).")
                    }
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(subscription)
                        debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventSucceded) Auto-Renewable Subscription added to purchased auto-renewable subscriptions.")
                    } else {
                        debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventFailed) Auto-Renewable Subscripton Product Id not within the offering : \(transaction.productID).")
                    }
                default:
                    debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventFailed) Hit default \(transaction.productID).")
                    break
                }
            } catch {
                debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventFailed) failed to grant product access \(result.debugDescription).")
            }
        }
        debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventInProgress) Updating Purchased Arrays... \(DebuggingIdentifiers.actionOrEventInProgress)")

        self.purchasedConsumables = purchasedConsumables
        
        // Update the store information with the purchased products.
        self.purchasedNonConsumables = purchasedNonConsumables
        self.purchasedNonRenewables = purchasedNonRenewableSubscriptions

        // Update the store information with auto-renewable subscription products.
        self.purchasedSubscriptions = purchasedSubscriptions

        debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventSucceded) Updated Purchased arrays.")

        debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventInProgress) Updating Subscription Group Status... \(DebuggingIdentifiers.actionOrEventInProgress)")
        // Check the `subscriptionGroupStatus` to learn the auto-renewable subscription state to determine whether the customer
        // is new (never subscribed), active, or inactive (expired subscription). This app has only one subscription
        // group, so products in the subscriptions array all belong to the same group. The statuses that
        // `product.subscription.status` returns apply to the entire subscription group.
        subscriptionGroupStatus = try? await subscriptions.first?.subscription?.status.first?.state
        
        #warning("support for multiple subscription groups")
//        var statuses:[RenewalState] = []
//        await subscriptions.asyncForEach { product in
//            if let status = try? await product.subscription?.status.first?.state {
//                statuses.append(status)
//            }
//        }
        
        debugPrint("\(StoreKitCoordinator.identifier) updateCustomerProductStatus \(DebuggingIdentifiers.actionOrEventSucceded) Updated Subscription Group Status.")
        // Notify System
        NotificationCenter.default.post(name: SK2Notifications.onStoreKitUpdate, object: nil)
    }
    
    public func verifyPremium() async -> PurchasesVerifyPremiumResult {
        var statuses:[VerifyPremiumStatus] = []
        await subscriptions.asyncForEach { product in
//            if let state = try? await product.subscription?.status.first?.state {
//                let premiumStatus = VerifyPremiumStatus(product: product, state: state)
//                statuses.append(premiumStatus)
//            }
            
            if let state = await getSubscriptionStatus(product: product) {
                let premiumStatus = VerifyPremiumStatus(product: product, state: state)
                statuses.append(premiumStatus)
            }
        }
        
        if let premium = statuses.first(where: {$0.state == .subscribed}) {
            return .premium(purchase: Purchase(product: premium.product))
        }else{
            return .notPremium
        }
    }
    
    func getSubscriptionStatus(product: Product) async -> RenewalState? {
        guard let subscription = product.subscription else {
            // Not a subscription
            return nil
        }
        do {
            let statuses = try await subscription.status
            
            for status in statuses {
                let info = try checkVerified(status.renewalInfo)
                switch status.state {
                case .subscribed:
                    if info.willAutoRenew {
                        debugPrint("getSubscriptionStatus user subscription is active.")
                    } else {
                        debugPrint("getSubscriptionStatus user subscription is expiring.")
                    }
                case .inBillingRetryPeriod:
                    debugPrint("getSubscriptionStatus user subscription is in billing retry period.")
                case .inGracePeriod:
                    debugPrint("getSubscriptionStatus user subscription is in grace period.")
                case .expired:
                    debugPrint("getSubscriptionStatus user subscription is expired.")
                case .revoked:
                    debugPrint("getSubscriptionStatus user subscription was revoked.")
                default:
                    fatalError("getSubscriptionStatus WARNING STATE NOT CONSIDERED.")
                }
                return status.state
            }
        } catch {
            return nil
        }
        return nil
    }
    
}

struct SK2Notifications {
    static let onStoreKitUpdate: Notification.Name = Notification.Name("onStoreKitUpdate")
    static let onStoreKitProductUpdate: Notification.Name = Notification.Name("onStoreKitProductUpdate")
    static let onStoreKitProductRefundUpdate: Notification.Name = Notification.Name("onStoreKitProductRefundUpdate")
}

extension Sequence {
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}

struct VerifyPremiumStatus {
    var product: Product
    var state: RenewalState
}
