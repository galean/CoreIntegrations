//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 1/2/24.
//

import Foundation

public protocol CorePaywallConfiguration: CaseIterable {
    associatedtype PurchaseIdentifier: CorePurchaseIdentifier
    
    var id: String { get }
    var purchases: [PurchaseIdentifier] { get }
}

public extension CorePaywallConfiguration {
    static func ==(lhs: any CorePaywallConfiguration, rhs: any CorePaywallConfiguration) -> Bool {
        return lhs.id == rhs.id
    }
    
    func purchases() async -> CorePaywallPurchasesResult {
        let result = await CoreManager.internalShared.purchases(config: self)
        return result
    }
    
}

extension CorePaywallConfiguration {
    static var allPurchasesIDs: [String] {
        return allPurchases.map({$0.id})
    }
    static var allProPurchasesIDs: [String] {
        return allProPurchases.map({$0.id})
    }
    
    static var allPurchases: [PurchaseIdentifier] {
        return PurchaseIdentifier.allCases as! [Self.PurchaseIdentifier]
    }
    
    static var allProPurchases: [PurchaseIdentifier] {
        return PurchaseIdentifier.allCases.filter({$0.purchaseGroup == .Pro})
    }
    
    var activeForPaywallIDs: [String] {
        return purchases.map({$0.id})
    }
}
