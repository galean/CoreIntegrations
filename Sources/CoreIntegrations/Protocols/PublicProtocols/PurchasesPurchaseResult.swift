
import Foundation
import StoreKit

public enum PurchasesPurchaseResult {
    case success(details: PurchaseDetails)
    case userCancelled
    case pending
    case unknown
    case error(_ error: String)
}
