
import Foundation

public struct AttributionConfigData {
    let authToken: AttributionServerToken
    let installServerURLPath: String
    let purchaseServerURLPath: String
    let externalAuthServerURLPath: String
    let installPath: String
    let purchasePath: String
    let externalAuthPath: String
    let appTransactionPath: String
    let appsflyerID: String?
    let appEnvironment: String?
    let facebookData: AttributionFacebookModel?
    let tokensPath: String
    let hasExternalAuth: Bool?
    let isAdPartnersDataSharingEnabled: Bool
    let adConsent: AttributionAdConsent?

    public init(authToken: AttributionServerToken, installServerURLPath: String, purchaseServerURLPath: String, 
                externalAuthServerURLPath: String, installPath: String, appTransactionPath: String = "/app-transaction",
                externalAuthPath: String, purchasePath: String, appsflyerID: String?, appEnvironment: String?,
                facebookData: AttributionFacebookModel?, tokensPath: String, hasExternalAuth: Bool?,
                isAdPartnersDataSharingEnabled: Bool, adConsent: AttributionAdConsent?) {
        self.authToken = authToken
        self.appsflyerID = appsflyerID
        self.facebookData = facebookData
        self.installServerURLPath = installServerURLPath
        self.purchaseServerURLPath = purchaseServerURLPath
        self.externalAuthServerURLPath = externalAuthServerURLPath
        self.installPath = installPath
        self.purchasePath = purchasePath
        self.appTransactionPath = appTransactionPath
        self.externalAuthPath = externalAuthPath
        self.appEnvironment = appEnvironment
        self.tokensPath = tokensPath
        self.hasExternalAuth = hasExternalAuth
        self.isAdPartnersDataSharingEnabled = isAdPartnersDataSharingEnabled
        self.adConsent = adConsent
    }
}

public struct AttributionConfigURLs {
    let installServerURLPath: String
    let purchaseServerURLPath: String
    let externalAuthServerURLPath: String
    let installPath: String
    let purchasePath: String
    let appTransactionPath: String
    let externalAuthPath: String
    let tokensPath: String
    
    public init(installServerURLPath: String, purchaseServerURLPath: String, externalAuthServerURLPath: String,
                appTransactionPath: String = "/app-transaction", installPath: String, 
				purchasePath: String, externalAuthPath: String, tokensPath: String) {
        self.installServerURLPath = installServerURLPath
        self.purchaseServerURLPath = purchaseServerURLPath
        self.installPath = installPath
        self.purchasePath = purchasePath
        self.appTransactionPath = appTransactionPath
        self.tokensPath = tokensPath
        self.externalAuthServerURLPath = externalAuthServerURLPath
        self.externalAuthPath = externalAuthPath
    }
}
