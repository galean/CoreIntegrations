
import Foundation

public struct AttributionConfigData {
    let authToken: AttributionServerToken
    let installServerURLPath: String
    let purchaseServerURLPath: String
    let installPath: String
    let purchasePath: String
    let appsflyerID: String?
    let facebookData: AttributionFacebookModel?
    
    public init(authToken: AttributionServerToken, installServerURLPath: String, purchaseServerURLPath: String, installPath: String, purchasePath: String,
                appsflyerID: String?, facebookData: AttributionFacebookModel?) {
        self.authToken = authToken
        self.appsflyerID = appsflyerID
        self.facebookData = facebookData
        self.installServerURLPath = installServerURLPath
        self.purchaseServerURLPath = purchaseServerURLPath
        self.installPath = installPath
        self.purchasePath = purchasePath
    }
}

public struct AttributionConfigURLs {
    let installServerURLPath: String
    let purchaseServerURLPath: String
    let installPath: String
    let purchasePath: String
    
    public init(installServerURLPath: String, purchaseServerURLPath: String, installPath: String, purchasePath: String) {
        self.installServerURLPath = installServerURLPath
        self.purchaseServerURLPath = purchaseServerURLPath
        self.installPath = installPath
        self.purchasePath = purchasePath
    }
}
