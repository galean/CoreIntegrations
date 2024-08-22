
import Foundation
import StoreKit

public enum PurchasesVerifyPremiumResult {
    case premium(purchase: Purchase)
    case notPremium
}
