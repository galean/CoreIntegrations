
import Foundation
import StoreKit

public enum PurchasesRestoreResult {
    case restore(purchases: [Purchase])
    case error(_ error: String)
}
