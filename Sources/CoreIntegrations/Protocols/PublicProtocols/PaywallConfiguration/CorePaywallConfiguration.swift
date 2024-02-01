//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 1/2/24.
//

import Foundation

public protocol CorePaywallConfiguration: CaseIterable {
    var id: String { get }
    var purchases: [String] { get }
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

#warning("PaywallConfig should look like this:")
//enum PaywallConfig: String, CaseIterable, CorePaywallConfiguration {
//    public var id: String { return rawValue }
//
//    case ct_3box_5
//    case ct_2box_1
//
//    var purchases:[SubscriptionKeys] {
//        switch self {
//        case .ct_3box_5:
//            return [.sub_weekly_19_99]
//        case .ct_2box_1:
//            return [.sub_yearly_99_99]
//        }
//    }
//}
//
//enum SubscriptionKeys: String, CaseIterable {
//    case sub_weekly_19_99 = "weekly.19.99"
//    case sub_yearly_99_99 = "yearly.99.99"
//}

