
import Foundation

public enum PurchaseBillingPlanType {
    case monthly
    case upFront
}

public struct PurchaseOptions {
    let billingPlanType: PurchaseBillingPlanType?
    
    public init() {
        self.billingPlanType = nil
    }

    @available(iOS 26.4, *)
    public init(billingPlanType: PurchaseBillingPlanType) {
        self.billingPlanType = billingPlanType
    }
}
