
import Foundation
import StoreKit
import UIKit
import LoggingIntegration

extension PurchasesManager {
    public func purchase(_ product: Product, activeController: UIViewController?) async throws -> SKPurchaseResult {
        return try await purchase(product, options: SKPurchaseOptions(), activeController: activeController)
    }

    public func purchase(_ product: Product, options purchaseOptions: SKPurchaseOptions, activeController: UIViewController?) async throws -> SKPurchaseResult {
        DebugLogger.log("🏦 purchase ⚈ ⚈ ⚈ Purchasing product \(product.displayName)... ⚈ ⚈ ⚈")

        return try await performPurchase(product, options: makeStoreKitOptions(purchaseOptions), activeController: activeController)
    }
    
    public func purchase(_ product: Product, promoOffer:SKPromoOffer, activeController: UIViewController?) async throws -> SKPurchaseResult {
        return try await purchase(product, promoOffer: promoOffer, options: SKPurchaseOptions(), activeController: activeController)
    }

    public func purchase(_ product: Product, promoOffer:SKPromoOffer, options purchaseOptions: SKPurchaseOptions, activeController: UIViewController?) async throws -> SKPurchaseResult {
        let promoOption = Product.PurchaseOption.promotionalOffer(
            offerID: promoOffer.offerID,
            keyID: promoOffer.keyID,
            nonce: promoOffer.nonce,
            signature: promoOffer.signature,
            timestamp: promoOffer.timestamp
        )
        var options = makeStoreKitOptions(purchaseOptions)
        options.insert(promoOption)

        return try await performPurchase(product, options: options, activeController: activeController)
    }

    private func makeStoreKitOptions(_ purchaseOptions: SKPurchaseOptions) -> Set<Product.PurchaseOption> {
        var options:Set<Product.PurchaseOption> = []
        if let userId = UUID(uuidString: self.userId) {
            options.insert(.appAccountToken(userId))
        }
        if #available(iOS 26.4, *), let billingPlanType = purchaseOptions.billingPlanType {
            switch billingPlanType {
            case .monthly:
                options.insert(.billingPlanType(.monthly))
            case .upFront:
                options.insert(.billingPlanType(.upFront))
            }
        }
        return options
    }

    private func performPurchase(_ product: Product, options: Set<Product.PurchaseOption>, activeController: UIViewController?) async throws -> SKPurchaseResult {
        DebugLogger.log("🏦 purchase ⚈ ⚈ ⚈ Purchasing product \(product.displayName)... ⚈ ⚈ ⚈")

        var result: Product.PurchaseResult
        
        if #available (iOS 18.2, *) {
            if let activeController {
                 result = try await product.purchase(confirmIn: activeController, options: options)
            }else{
                 result = try await product.purchase(options: options)
            }
        }else{
             result = try await product.purchase(options: options)
        }
        
        switch result {
        case .success(let verification):
            DebugLogger.log("🏦 purchase ✅ Product Purchased.")
            DebugLogger.log("🏦 purchase ⚈ ⚈ ⚈ Verifying... ⚈ ⚈ ⚈")
            let transaction = try checkVerified(verification)
            DebugLogger.log("🏦 purchase ✅ Verified.")
            DebugLogger.log("🏦 purchase ⚈ ⚈ ⚈ Updating Product status... ⚈ ⚈ ⚈")
            await updateProductStatus()
            DebugLogger.log("🏦 purchase ✅ Updated product status.")
            await transaction.finish()
            DebugLogger.log("🏦 purchase ✅ Finished transaction.")
            
            let purchaseInfo = SKPurchaseInfo(transaction: transaction, jsonRepresentation: transaction.jsonRepresentation, jwsRepresentation: verification.jwsRepresentation, originalID: "\(transaction.originalID)")
            return .success(transaction: purchaseInfo)
        case .pending:
            DebugLogger.log("🏦 purchase ❌ Failed as the transaction is pending.")
            return .pending
        case .userCancelled:
            DebugLogger.log("🏦 purchase ❌ Failed as the user cancelled the purchase.")
            return .userCancelled
        default:
            DebugLogger.log("🏦 purchase ❌ Failed with result \(result).")
            return .unknown
        }
    }
    
    //This call displays a system prompt that asks users to authenticate with their App Store credentials.
    //Call this function only in response to an explicit user action, such as tapping a button.
    public func restore() async -> SKRestoreResult {
        do {
            try await AppStore.sync()
        }
        catch {
            return .error(error.localizedDescription)
        }
        var products:[Product] = []
        products.append(contentsOf: self.purchasedConsumables)
        products.append(contentsOf: self.purchasedNonConsumables)
        products.append(contentsOf: self.purchasedSubscriptions)
        products.append(contentsOf: self.purchasedNonRenewables)
        return .success(products: products)
    }
    
    public func restoreAll() async -> SKRestoreResult {
        let allProducts = await updateAllProductsStatus()
        
        return .success(products: allProducts)
    }
    
    public func verifyPremium() async -> SKVerifyPremiumResult {
        DebugLogger.log("🏦 verifyPremium ⚈ ⚈ ⚈ Verifying... ⚈ ⚈ ⚈")
        await updateProductStatus()
        
        var statuses:[SKVerifyPremiumState] = []
        
        purchasedNonConsumables.forEach { product in
            if proIdentifiers.contains(where: {$0 == product.id}) {
                DebugLogger.log("🏦 verifyPremium ✅ non-consumable \(product.id) status 'purchased' verified")
                let premiumStatus = SKVerifyPremiumState(product: product, state: .subscribed)
                statuses.append(premiumStatus)
            }
        }
        
        purchasedSubscriptions.forEach { product in
            if proIdentifiers.contains(where: {$0 == product.id}) {
                let premiumStatus = SKVerifyPremiumState(product: product, state: .subscribed)
                statuses.append(premiumStatus)
            }
        }

        if let premium = statuses.last(where: {$0.state == .subscribed || $0.state == .inGracePeriod}) {
            DebugLogger.log("🏦 verifyPremium ✅ return active premium product \(premium.product.id) status \(premium.state), \(premium.state.rawValue)")
            return .premium(purchase: premium.product)
        }else{
            return .notPremium
        }
    }
    
    public func verifyAll() async -> SKVerifyAllResult {
        DebugLogger.log("🏦 verifyAll ⚈ ⚈ ⚈ Verifying... ⚈ ⚈ ⚈")
        await updateProductStatus()
        
        DebugLogger.log("🏦 verifyAll ✅ completed! consumables: \(self.purchasedConsumables)\n nonConsumables: \(self.purchasedNonConsumables)\n subscriptions: \(self.purchasedSubscriptions)\n nonRenewables \(self.purchasedNonRenewables)")
        
        var products:[Product] = []
        products.append(contentsOf: self.purchasedConsumables)
        products.append(contentsOf: self.purchasedNonConsumables)
        products.append(contentsOf: self.purchasedSubscriptions)
        products.append(contentsOf: self.purchasedNonRenewables)
        return .success(products: products)
    }
}
