
import FirebaseAnalytics
import FirebaseCore

public class FirebaseManager {
    public init() {
        
    }
    
    public func configure(id: String, completion: @escaping () -> Void) {
        FirebaseApp.configure()
        Analytics.logEvent("Firebase Init", parameters: nil)
        Analytics.setUserID(id)
        completion()
    }
}
