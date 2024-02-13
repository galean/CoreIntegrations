//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 13/2/24.
//

import Foundation
import StoreKit

extension PurchasesManager {
    public func purchase(_ product: Product) async throws -> SKPurchaseResult {
        debugPrint("🏦 purchase ⚈ ⚈ ⚈ Purchasing product \(product.displayName)... ⚈ ⚈ ⚈")
//         for future
//        product.purchase(options: [.promotionalOffer(offerID: <#T##String#>, keyID: <#T##String#>, nonce: <#T##UUID#>, signature: <#T##Data#>, timestamp: <#T##Int#>)])
//        product.purchase(options: [.appAccountToken(UUID())]), promoOffer?
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            debugPrint("🏦 purchase ✅ Product Purchased.")
            debugPrint("🏦 purchase ⚈ ⚈ ⚈ Verifying... ⚈ ⚈ ⚈")
            let transaction = try checkVerified(verification)
            debugPrint("🏦 purchase ✅ Verified.")
            debugPrint("🏦 purchase ⚈ ⚈ ⚈ Updating Product status... ⚈ ⚈ ⚈")
            await updateProductStatus()
            debugPrint("🏦 purchase ✅ Updated product status.")
            await transaction.finish()
            debugPrint("🏦 purchase ✅ Finished transaction.")
            
            let purchaseInfo = SKPurchaseInfo(transaction: transaction, jsonRepresentation: transaction.jsonRepresentation, jwsRepresentation: verification.jwsRepresentation, originalID: "\(transaction.originalID)")
            return .success(transaction: purchaseInfo)
        case .pending:
            debugPrint("🏦 purchase ❌ Failed as the transaction is pending.")
            return .pending
        case .userCancelled:
            debugPrint("🏦 purchase ❌ Failed as the user cancelled the purchase.")
            return .userCancelled
        default:
            debugPrint("🏦 purchase ❌ Failed with result \(result).")
            return .unknown
        }
    }
    
    //This call displays a system prompt that asks users to authenticate with their App Store credentials.
    //Call this function only in response to an explicit user action, such as tapping a button.
    public func restore() async -> SKRestoreResult {
        try? await AppStore.sync()
        
        return .restore(consumables: self.purchasedConsumables,
                        nonConsumables: self.purchasedNonConsumables,
                        subscriptions: self.purchasedSubscriptions,
                        nonRenewables: self.purchasedNonRenewables)
    }
    
    public func verifyPremium() async -> PurchasesVerifyPremiumResult {
        var statuses:[VerifyPremiumStatus] = []
        await subscriptions.asyncForEach { product in
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
}
