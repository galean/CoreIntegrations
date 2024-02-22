//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 13/2/24.
//

import Foundation
import StoreKit

extension PurchasesManager {
    public func updateProductStatus() async {
        debugPrint("🏦 updateCustomerProductStatus ⚈ ⚈ ⚈ Updating Customer Product Status... ⚈ ⚈ ⚈")
        var purchasedConsumables: [Product] = []
        var purchasedNonConsumables: [Product] = []
        var purchasedSubscriptions: [Product] = []
        var purchasedNonRenewableSubscriptions: [Product] = []

        for await result in Transaction.currentEntitlements {
            do {
                debugPrint("🏦 updateCustomerProductStatus ⚈ ⚈ ⚈ Checking verification for product \(result.debugDescription)... ⚈ ⚈ ⚈")
                let transaction = try checkVerified(result)

                switch transaction.productType {
                case .consumable:
                    if let consumable = consumables.first(where: { $0.id == transaction.productID }) {
                        purchasedConsumables.append(consumable)
                        debugPrint("🏦 updateCustomerProductStatus ✅ Consumable added to purchased Non-Consumables.")
                    } else {
                        debugPrint("🏦 updateCustomerProductStatus ❌ Consumable Product Id not within the offering : \(transaction.productID).")
                    }
                case .nonConsumable:
                    if let nonConsumable = nonConsumables.first(where: { $0.id == transaction.productID }) {
                        purchasedNonConsumables.append(nonConsumable)
                        debugPrint("🏦 updateCustomerProductStatus ✅ Non-Consumable added to purchased Non-Consumables.")
                    } else {
                        debugPrint("🏦 updateCustomerProductStatus ❌ Non-Consumable Product Id not within the offering : \(transaction.productID).")
                    }
                case .nonRenewable:
                    if let nonRenewable = nonRenewables.first(where: { $0.id == transaction.productID }) {
                        let currentDate = Date()
                        let expirationDate = Calendar(identifier: .gregorian).date(byAdding: DateComponents(year: 1),
                                                                                   to: transaction.purchaseDate)!

                        if currentDate < expirationDate {
                            purchasedNonRenewableSubscriptions.append(nonRenewable)
                            debugPrint("🏦 updateCustomerProductStatus ✅ Non-Renewing Subscription added to purchased non-renewing subscriptions.")
                        } else {
                            debugPrint("🏦 updateCustomerProductStatus ❌ Non-Renewing Subscription with Id  \(transaction.productID) expired.")
                        }
                    } else {
                        debugPrint("🏦 updateCustomerProductStatus ❌ Non-Renewing Subscription Product Id not within the offering : \(transaction.productID).")
                    }
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(subscription)
                        debugPrint("🏦 updateCustomerProductStatus ✅ Auto-Renewable Subscription added to purchased auto-renewable subscriptions.")
                    } else {
                        debugPrint("🏦 updateCustomerProductStatus ❌ Auto-Renewable Subscripton Product Id not within the offering : \(transaction.productID).")
                    }
                default:
                    debugPrint("🏦 updateCustomerProductStatus ❌ Hit default \(transaction.productID).")
                    break
                }
            } catch {
                debugPrint("🏦 updateCustomerProductStatus ❌ failed to grant product access \(result.debugDescription).")
            }
        }
        debugPrint("🏦 updateCustomerProductStatus ⚈ ⚈ ⚈ Updating Purchased Arrays... ⚈ ⚈ ⚈")

        self.purchasedConsumables = purchasedConsumables
        self.purchasedNonConsumables = purchasedNonConsumables
        self.purchasedNonRenewables = purchasedNonRenewableSubscriptions
        self.purchasedSubscriptions = purchasedSubscriptions

        debugPrint("🏦 updateCustomerProductStatus ✅ Updated Purchased arrays.")
    }
    
    
    
    public func getSubscriptionStatus(product: Product) async -> RenewalState? {
        guard let subscription = product.subscription else {
            // Not a subscription
            return nil
        }
        do {
            debugPrint("🏦 ⚈ ⚈ ⚈ getSubscriptionStatuses ⚈ ⚈ ⚈")
            let statuses = try await subscription.status
            debugPrint("🏦 getSubscriptionStatuses ✅ \(statuses) for product \(product.id)")
            
            for status in statuses {
                debugPrint("🏦 getSubscriptionStatuses ✅ status check \(status)")
                let info = try checkVerified(status.renewalInfo)
                debugPrint("🏦 getSubscriptionStatuses ✅ status state \(status.state)")
                switch status.state {
                case .subscribed:
                    if info.willAutoRenew {
                        debugPrint("🏦 getSubscriptionStatus user subscription is active.")
                    } else {
                        debugPrint("🏦 getSubscriptionStatus user subscription is expiring.")
                    }
                case .inBillingRetryPeriod:
                    debugPrint("🏦 getSubscriptionStatus user subscription is in billing retry period.")
                case .inGracePeriod:
                    debugPrint("🏦 getSubscriptionStatus user subscription is in grace period.")
                case .expired:
                    debugPrint("🏦 getSubscriptionStatus user subscription is expired.")
                case .revoked:
                    debugPrint("🏦 getSubscriptionStatus user subscription was revoked.")
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
