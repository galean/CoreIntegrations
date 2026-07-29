
import Foundation
import StoreKit
import LoggingIntegration

extension PurchasesManager {
    @MainActor
    public func isPurchased(_ product: Product) async throws -> Bool {
        DebugLogger.log("🏦 isPurchased ⚈ ⚈ ⚈ Checking if the product is purchased... ⚈ ⚈ ⚈")
        switch product.type {
        case .nonRenewable:
            DebugLogger.log("🏦 isPurchased ✅ Non-Renewing Subscription has been purchased : \(purchasedNonRenewables.contains(product)).")
            return purchasedNonRenewables.contains(product)
        case .nonConsumable:
            DebugLogger.log("🏦 isPurchased ✅ Non-Consumable has been purchased : \(purchasedNonConsumables.contains(product)).")
            return purchasedNonConsumables.contains(product)
        case .autoRenewable:
            DebugLogger.log("🏦 isPurchased ✅ Auto-Renewable Subscription has been purchased : \(purchasedSubscriptions.contains(product)).")
            return purchasedSubscriptions.contains(product)
        case .consumable:
            DebugLogger.log("🏦 isPurchased ❌ Consumables cannot be checked off as purchased.")
            return false
        default:
            DebugLogger.log("🏦 isPurchased ❌ Failed as the type '\(product.type)' is unidentified.")
            return false
        }
    }

    public func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        DebugLogger.log("🏦 checkVerified ⚈ ⚈ ⚈ Checking verification... ⚈ ⚈ ⚈")
        switch result {
        case .unverified(let safe, let verificationError):
            DebugLogger.log("🏦 checkVerified ❌ Not verified.")
            throw verificationError
        case .verified(let safe):
            DebugLogger.log("🏦 checkVerified ✅ Verified.")
            return safe
        }
    }
}

