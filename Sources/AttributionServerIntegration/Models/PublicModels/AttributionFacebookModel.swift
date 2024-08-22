
import Foundation

public struct AttributionFacebookModel {
    var fbUserId: String
    var fbUserData: String
    var fbAnonId: String
    
    public init(fbUserId: String, fbUserData: String, fbAnonId: String) {
        self.fbUserId = fbUserId
        self.fbUserData = fbUserData
        self.fbAnonId = fbAnonId
    }
}
