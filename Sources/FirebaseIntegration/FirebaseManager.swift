
import FirebaseAnalytics
import FirebaseCore

public class FirebaseManager {
    public init() {
        
    }
    
    public func configure(id: String) {
        FirebaseApp.configure()
        Analytics.logEvent("Firebase Init", parameters: nil)
        Analytics.setUserID(id)
    }
    
    public func sendPurchaseAnalytics(_ analData: FirebasePurchaseData) {
        guard analData.isTrial else { return }
        
        let parameters: [String: Any] = [
            "product_id": analData.subscriptionID,
            "currency": analData.currencyCode,
            "price": analData.price,
            "trial_price": analData.trialPrice
        ]
        
        Analytics.logEvent("trial_started", parameters: parameters)
    }
}
