
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
}
