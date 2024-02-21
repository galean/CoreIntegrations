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
        return allPurchases.map({$0.rawValue})
    }
    
    static var allPurchases: [PurchaseIdentifier] {
        return PurchaseIdentifier.allCases as! [Self.PurchaseIdentifier]
    }
    
    var activeForPaywallIDs: [String] {
        return purchases.map({$0.rawValue})
    }
}

public protocol CorePurchaseGroup: CaseIterable {
  static var Pro: Self { get }
}

#warning("PaywallConfig should look like this:")
/*
enum AppPaywallIdentifier: String, CaseIterable, CorePaywallConfiguration {
    public typealias CorePurchaseIdentifier = AppPurchaseIdentifier
    
    public var id: String { return rawValue }
    
    case ct_vap_1 = "3_box"
    case ct_vap_2 = "clear_trial_vap"
    case ct_vap_3 = "ct_vap_3"
    
    var purchases: [CorePurchaseIdentifier] {
        switch self {
        case .ct_vap_1:
            return [.annual_34_99]
        case .ct_vap_2, .ct_vap_3:
            return [.weekly_9_99, .lifetime_34_99]
        }
    }
    
}

public enum AppPurchaseIdentifier: String, CaseIterable {
  public var id: String { return rawValue }

  case annual_34_99 = "annual.34.99"
  case weekly_9_99 = "week.9.99"
  case lifetime_34_99 = "lifetime.99.99"

  var purchaseGroup: AppPurchaseGroup {
    switch self {
    case .annual_34_99, .weekly_9_99, .lifetime_34_99:
      return .Pro
    }
  }
    
}

public enum AppPurchaseGroup: CorePurchaseGroup {
  case Pro
}

struct PaywallDataSource: CorePaywallDataSource {
    typealias PurchaseGroup = AppPurchaseGroup
    typealias PaywallInitialConfiguration = AppPaywallIdentifier
}
*/
