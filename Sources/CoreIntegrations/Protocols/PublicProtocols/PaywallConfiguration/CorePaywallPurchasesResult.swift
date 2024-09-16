
import Foundation
#if !COCOAPODS
import PurchasesIntegration
#endif

public enum CorePaywallPurchasesResult {
    case success(purchases: [Purchase])
    case error(_ error: String)
}
