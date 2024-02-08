//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 1/2/24.
//

import Foundation
import StoreKit

public enum PurchaseType: String {
    case consumable,
         nonConsumable,
         nonRenewable,
         autoRenewable,
         unknown
}

public enum PurchasePeriod: String {
    case daily, weekly, monthly, quarterly, annual
}

public struct Purchase: Hashable {
    public let product: Product
    
    public init(product: Product) {
        self.product = product
    }
    
    public var storeProduct: Product {
        return product
    }
    
    public var isSubscription: Bool {
        let isSubscription = product.type == .autoRenewable || product.type == .nonRenewable
        return isSubscription
    }
    
    public var purchaseType:PurchaseType {
        return PurchaseType(rawValue: product.type.rawValue) ?? .unknown
    }
    
    public var identifier:String {
        return product.id
    }
    
    public var localisedPrice: String {
        return product.displayPrice
    }
    
    public var localizedIntroductoryPriceString: String? {
        return product.subscription?.introductoryOffer?.displayPrice
    }
    
    public var priceFloat: CGFloat {
        CGFloat(NSDecimalNumber(decimal: product.price).floatValue)
    }
    
    public var period: PurchasePeriod {
        let count = product.subscription?.subscriptionPeriod.value ?? 0
        switch product.subscription?.subscriptionPeriod.unit {
        case .day:
            return .daily
        case .week:
            return .weekly
        case .month:
            if count == 3 {
                return .quarterly
            }
            return .monthly
        case .year:
            return .annual
        default:
            return .weekly
        }
    }
    
    public var periodString: String {
        let count = product.subscription?.subscriptionPeriod.value ?? 0
        switch product.subscription?.subscriptionPeriod.unit {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            if count == 3 {
                return "quarter"
            }
            return "month"
        case .year:
            return "year"
        case nil:
            return ""
        case .some(_):
            return ""
        }
    }
    
    public var trialPeriodString: String {
        switch product.subscription?.introductoryOffer?.period.unit {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        case nil:
            return ""
        case .some(_):
            return ""
        }
    }
    
    public var periodCount: Int {
        return product.subscription?.subscriptionPeriod.value ?? 0
    }
    
    public var trialCount: Int {
        return product.subscription?.introductoryOffer?.period.value ?? 0
    }
    
    public var currencyCode:String {
        return product.priceFormatStyle.currencyCode
    }
}
