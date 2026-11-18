
import Foundation

public enum SKBillingPlanType {
    case monthly
    case upFront
}

public struct SKPurchaseOptions {
    let billingPlanType: SKBillingPlanType?
    
    public init() {
        self.billingPlanType = nil
    }

    @available(iOS 26.4, *)
    public init(billingPlanType: SKBillingPlanType) {
        self.billingPlanType = billingPlanType
    }
}
