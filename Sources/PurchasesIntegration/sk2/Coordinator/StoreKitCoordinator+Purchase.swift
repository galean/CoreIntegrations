import Foundation
import StoreKit

extension StoreKitCoordinator {
    public func purchase(_ product: Product) async throws -> SKPurchaseResult {
        debugPrint("\(StoreKitCoordinator.identifier) purchase \(DebuggingIdentifiers.actionOrEventInProgress) Purchasing product \(product.displayName)... \(DebuggingIdentifiers.actionOrEventInProgress)")
        // Begin purchasing the `Product` the user selects.
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            debugPrint("\(StoreKitCoordinator.identifier) purchase \(DebuggingIdentifiers.actionOrEventSucceded) Product Purchased.")
            debugPrint("\(StoreKitCoordinator.identifier) purchase \(DebuggingIdentifiers.actionOrEventInProgress) Verifying... \(DebuggingIdentifiers.actionOrEventInProgress)")
            // Check whether the transaction is verified. If it isn't,
            // this function rethrows the verification error.
            let transaction = try checkVerified(verification)
            debugPrint("\(StoreKitCoordinator.identifier) purchase \(DebuggingIdentifiers.actionOrEventSucceded) Verified.")
            // The transaction is verified. Deliver content to the user.
            debugPrint("\(StoreKitCoordinator.identifier) purchase \(DebuggingIdentifiers.actionOrEventInProgress) Updating Product status... \(DebuggingIdentifiers.actionOrEventInProgress)")
            await updateCustomerProductStatus()
            debugPrint("\(StoreKitCoordinator.identifier) purchase \(DebuggingIdentifiers.actionOrEventSucceded) Updated product status.")
            // Always finish a transaction - This removes transactions from the queue and it tells Apple that the customer has recieved their items or service.
            await transaction.finish()
            debugPrint("\(StoreKitCoordinator.identifier) purchase \(DebuggingIdentifiers.actionOrEventSucceded) Finished transaction.")
            return .success(transaction: transaction)
        case .pending:
            debugPrint("\(StoreKitCoordinator.identifier) purchase \(DebuggingIdentifiers.actionOrEventFailed) Failed as the transaction is pending.")
            return .pending
        case .userCancelled:
            debugPrint("\(StoreKitCoordinator.identifier) purchase \(DebuggingIdentifiers.actionOrEventFailed) Failed as the user cancelled the purchase.")
            return .userCancelled
        default:
            debugPrint("\(StoreKitCoordinator.identifier) purchase \(DebuggingIdentifiers.actionOrEventFailed) Failed with result \(result).")
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
}