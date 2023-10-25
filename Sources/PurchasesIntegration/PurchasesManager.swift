import SwiftyStoreKit
import StoreKit
import Foundation

extension PurchasesManager: PurchasesManagerProtocol {
    public func completeTransaction() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                // Unlock content
                case .failed, .purchasing, .deferred:
                    break // do nothing
                @unknown default:
                    break // do nothing
                }
            }
        }
    }
    
    public func purchase(_ purchaseID: String, quantity: Int = 1, atomically: Bool = true,
                  completion: @escaping (_ result: PurchasesPurchaseResult) -> Void) {
        SwiftyStoreKit.purchaseProduct(purchaseID, quantity: quantity, atomically: atomically) {
            result in
            switch result {
            case .success(let purchase):
                completion(.success(details: purchase))
            case .error(let error):
                switch error.code {
                case .paymentCancelled:
                    completion(.cancelled)
                case .cloudServiceNetworkConnectionFailed:
                    completion(.internetError)
                default:
                    completion(.error(skerror: error))
                }
            case .deferred:
                completion(.deferredPurchase)
            }
        }
    }
    
    public func verifyPremium(premiumSubscriptionIds: Set<String>,
                       premiumPurchaseIds: Set<String>,
                       completion: @escaping (_ result: PurchasesVerifyPremiumResult) -> Void) {
        restore(subscriptionIds: premiumSubscriptionIds, purchaseIds: premiumPurchaseIds) { result in
            switch result {
            case .success(let restoredItems):
                // If there would be an error, better app would crash and I would be guilty, then user won't be able to restore his premium status, while he paid and legal
                completion(.premium(receiptItem: restoredItems.first!))
            case .nothingToRestore:
                completion(.notPremium)
            case .internetError:
                completion(.internetError)
            case .error(let receiptError):
                completion(.error(receiptError: receiptError))
            }
        }
    }
    
    public func restore(subscriptionIds: Set<String>,
                 purchaseIds: Set<String>,
                 completion: @escaping (_ result: PurchasesVerifyResult) -> Void) {
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: subscriptionSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                self.verifySubscriptions(in: receipt, subscriptions: subscriptionIds) {
                    (subscriptionItems) in
                    self.verifyPurchases(productIDs: purchaseIds, receipt: receipt) {
                        (purchaseItems) in
                        let allPurchases = subscriptionItems + purchaseItems
                        if allPurchases.isEmpty {
                            completion(.nothingToRestore)
                        } else {
                            completion(.success(restoredItems: allPurchases))
                        }
                    }
                }
            case .error(let error):
                switch error {
                case .networkError(let error):
                    completion(.internetError)
                default:
                    completion(.error(receiptError: error))
                }
            }
        }
    }
    
    
}

public class PurchasesManager {
    private var subscriptionSecret: String
    
    public required init(subscriptionSecret: String) {
        self.subscriptionSecret = subscriptionSecret
    }
    
    private func verifySubscriptions(in receipt: ReceiptInfo,
                                     subscriptions: Set<String>,
                                     completion: @escaping (_ receiptItems: [ReceiptItem]) -> Void) {
        guard subscriptions.isEmpty == false else {
            completion([])
            return
        }
        let purchaseResult = SwiftyStoreKit.verifySubscriptions(
            ofType: .autoRenewable,
            productIds: subscriptions,
            inReceipt: receipt)
        
        switch purchaseResult {
        case .purchased(_, let items):
            completion(items)
        case .expired, .notPurchased:
            completion([])
        }
    }
    
    func verifyPurchases(productIDs: Set<String>, receipt: ReceiptInfo,
                         completion: @escaping (_ purchases: [ReceiptItem]) -> Void) {
        guard productIDs.isEmpty == false else {
            completion([])
            return
        }
        
        var receiptItems = [ReceiptItem]()
        let group = DispatchGroup()
        for productID in productIDs {
            group.enter()
            self.verifyPurchase(receipt: receipt, productID: productID) {
                (receiptItemOpt) in
                if let receiptItem = receiptItemOpt {
                    receiptItems.append(receiptItem)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .global()) {
            completion(receiptItems)
        }
    }
    
    func verifyPurchase(receipt: ReceiptInfo,
                        productID: String,
                        completion: @escaping (_ receiptItem: ReceiptItem?) -> Void) {
        let purchaseResult = SwiftyStoreKit.verifyPurchase(productId: productID,
                                                           inReceipt: receipt)
        
        switch purchaseResult {
        case .purchased(let receiptItem):
            completion(receiptItem)
        case .notPurchased:
            completion(nil)
        }
    }
}
