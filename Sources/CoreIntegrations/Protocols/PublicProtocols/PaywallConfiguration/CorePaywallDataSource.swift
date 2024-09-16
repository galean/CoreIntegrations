
import Foundation

public protocol CorePaywallDataSource {
    associatedtype PaywallInitialConfiguration: CorePaywallConfiguration
    associatedtype PurchaseGroup: CorePurchaseGroup
    
    var allConfigs: [PaywallInitialConfiguration] { get }
}

public extension CorePaywallDataSource {
    var allConfigs: [PaywallInitialConfiguration] {
        return PaywallInitialConfiguration.allCases as! [Self.PaywallInitialConfiguration]
    }
}

extension CorePaywallDataSource {
    var allPurchaseIDs: [String] {
        return PaywallInitialConfiguration.allPurchasesIDs
    }
    var allProPurchaseIDs: [String] {
        return PaywallInitialConfiguration.allProPurchasesIDs
    }
    var allPurchaseIdentifiers: [any CorePurchaseIdentifier] {
        return PaywallInitialConfiguration.allPurchases
    }
}
