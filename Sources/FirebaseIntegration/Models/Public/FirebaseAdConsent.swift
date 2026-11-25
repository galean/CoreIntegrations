
import Foundation

public struct FirebaseAdConsent {
    let isAdUserDataGranted: Bool
    let isAdPersonalizationGranted: Bool
    
    public init(isAdUserDataGranted: Bool, isAdPersonalizationGranted: Bool) {
        self.isAdUserDataGranted = isAdUserDataGranted
        self.isAdPersonalizationGranted = isAdPersonalizationGranted
    }
}
