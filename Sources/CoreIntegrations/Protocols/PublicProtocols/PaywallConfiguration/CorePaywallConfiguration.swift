//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 1/2/24.
//

import Foundation

public protocol CorePaywallConfiguration: CaseIterable {
    associatedtype PurchaseIdentifier: RawRepresentable, CaseIterable where PurchaseIdentifier.RawValue == String
    
    var id: String { get }
    var purchaseIdentifiers: [PurchaseIdentifier] { get }
    
    var allIdentifiers: [String] { get }
}

public extension CorePaywallConfiguration {
    static func ==(lhs: any CorePaywallConfiguration, rhs: any CorePaywallConfiguration) -> Bool {
        return lhs.id == rhs.id
    }
    
    func purchases() async -> CorePaywallPurchasesResult {
        let result = await CoreManager.internalShared.purchases(config: self)
        return result
    }
    
    var allIdentifiers: [String] {
        let ids: [String] = purchaseIdentifiers.map { $0.rawValue }
        return ids
    }
}

#warning("PaywallConfig should look like this:")
/*
enum PWconfig: String, CaseIterable, CorePaywallConfiguration {
    typealias PurchaseIdentifiers = PurchasesKeys
    
    public var id: String { return rawValue }
    
    case ct3box
    case ct4box
    
    var purchaseIdentifiers: [PurchaseIdentifiers] {
        switch self {
        case .ct3box:
            return [.test1]
        case .ct4box:
            return [.test2]
        }
    }
}
//
enum PurchasesKeys: String, CaseIterable {
    public var id: String { return rawValue }
    case test1 = "1"
    case test2 = "2"
}
*/
