
import Foundation
import StoreKit

public enum SKRestoreResult {
//    case success(consumables: [Product], nonConsumables : [Product], subscriptions: [Product], nonRenewables: [Product])
    case success(products: [Product])
    case error(_ error: String)
}
