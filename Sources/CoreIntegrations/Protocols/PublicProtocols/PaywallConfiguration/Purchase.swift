//
//  Purchase.swift
//
//
//  Created by Anatolii Kanarskyi on 15/11/23.
//

import Foundation
import RevenueCat

public enum PurchaseType: Int {
    case unknown = -2,
    custom,
    lifetime,
    annual,
    sixMonth,
    threeMonth,
    twoMonth,
    monthly,
    weekly
}

public struct Purchase: Hashable {
    public let package: Package
    
    init(package: Package) {
        self.package = package
    }
    
    public var storeProduct: StoreProduct {
        return package.storeProduct
    }
    
    public var isSubscription: Bool {
        let isSubscription = package.storeProduct.productType == .autoRenewableSubscription || package.storeProduct.productType == .nonRenewableSubscription
        return isSubscription
    }
    
    public var purchaseType:PurchaseType {
        return PurchaseType(rawValue: package.packageType.rawValue) ?? .unknown
    }
    
    public var identifier:String {
        return package.storeProduct.productIdentifier
    }
    
    public var localisedPrice: String {
        return package.localizedPriceString
    }
    
    public var localizedIntroductoryPriceString: String? {
        return package.localizedIntroductoryPriceString
    }
    
    public var priceFloat: CGFloat {
        CGFloat(NSDecimalNumber(decimal: package.storeProduct.price).floatValue)
    }
    
    public var periodString: String {
        let count = package.storeProduct.subscriptionPeriod?.value ?? 0
        switch package.storeProduct.subscriptionPeriod?.unit {
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
        }
    }
    
    public var trialPeriodString: String {
        switch package.storeProduct.introductoryDiscount?.subscriptionPeriod.unit {
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
        }
    }
    
    public var periodCount: Int {
        return package.storeProduct.subscriptionPeriod?.value ?? 0
    }
    
    public var trialCount: Int {
        return package.storeProduct.introductoryDiscount?.subscriptionPeriod.value ?? 0
    }
}
