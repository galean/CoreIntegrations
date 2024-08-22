
import Foundation

public protocol CorePurchaseIdentifier: CaseIterable {
    var id: String { get }
    var purchaseGroup: any CorePurchaseGroup { get }
}
