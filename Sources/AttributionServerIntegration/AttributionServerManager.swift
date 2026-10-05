import Foundation
import AdSupport
import AdServices
import AppTrackingTransparency
import LoggingIntegration

extension AttributionServerManager: AttributionServerManagerProtocol {
    public var savedUserUUID: String? {
        return udefWorker.getServerUserID()
    }
    
    public var fcmToken: String? {
        return udefWorker.getFCMToken()
    }
    
    public var installResultData: AttributionManagerResult? {
        return udefWorker.getInstallResult()
    }
    
    public func configure(config: AttributionConfigData) {
        self.facebookData = config.facebookData
        self.appsflyerID = config.appsflyerID
        self.appEnvironment = config.appEnvironment
        authorizationToken = config.authToken
        shouldAwaitExternalAuth = config.hasExternalAuth
        
        serverWorker = AttributionServerWorker(installServerURLPath: config.installServerURLPath,
                                               purchaseServerURLPath: config.purchaseServerURLPath,
                                               installPath: config.installPath,
                                               purchasePath: config.purchasePath,
                                               appTransactionPath: config.appTransactionPath,
                                               externalAuthPath: config.externalAuthPath,
                                               tokensPath: config.tokensPath)
    }

    public func configureURLs(config: AttributionConfigURLs) {
        serverWorker = AttributionServerWorker(installServerURLPath: config.installServerURLPath,
                                               purchaseServerURLPath: config.purchaseServerURLPath,
                                               installPath: config.installPath,
                                               purchasePath: config.purchasePath,
                                               appTransactionPath: config.appTransactionPath,
                                               externalAuthPath: config.externalAuthPath,
                                               tokensPath: config.tokensPath)
    }
    
    public func syncOnAppStart(_ completion: @escaping (AttributionManagerResult?) -> Void) {
        guard validateToken(authorizationToken) else {
            assertionFailure("No token")
            return
        }
        
        guard let userID = validateInstallAttributed() else {
            Task {
                let installData: AttributionInstallRequestModel
                if let savedInstallData = udefWorker.getInstallData() {
                    installData = savedInstallData
                } else {
                    installData = await collectInstallData()
                }
                
                sendInstallData(installData, authToken: authorizationToken, completion: completion)
            }
            return
        }
        
        /*
         The install is already registered - on an earlier launch or attempt, or by a purchase or an
         external authorization in between - so this completes with the saved result. Deferred to
         main, so the completion never runs synchronously, nested in the caller.
         */
        let installResult = installResultData
        if installResult == nil {
            DebugLogger.log("AttributionServerManager: server user ID is saved without an install result")
        }
        DispatchQueue.main.async {
            // The install is registered: an error another install request wrote meanwhile - even after
            // this call returned - must not be reported for it. Cleared here, right before delivery.
            self.installError = nil
            completion(installResult)
        }
        
        checkAndSendSavedPurchase(userId: userID)
        checkAndSendAppTransaction()
        checkAndSendSavedExternalAuth(userId: userID)
    }

    public func syncPurchase(data: AttributionPurchaseModel) {
        guard authorizationToken != nil else {
            assertionFailure("TLMAnalyticsSender error: Auth token not found")
            return
        }
        
        DispatchQueue.global().async {
            self.checkAndSendPurchase(data)
        }
    }
    
    public func sendExternalAuthorization(externalAuthID: String) {
        guard authorizationToken != nil else {
            assertionFailure("TLMAnalyticsSender error: Auth token not found")
            return
        }
        
        DispatchQueue.global().async {
            self.checkAndSendExternalAuth(externalAuthID)
        }
    }
}

open class AttributionServerManager {
    public static var shared: AttributionServerManager = AttributionServerManager()
    public var installError: Error? = nil
    public var uniqueUserID: String? {
        return udefWorker.uuid
    }
    
    var serverWorker: AttributionServerWorkerProtocol?
    let udefWorker: AttributionUserDefaultsWorkerProtocol = AttributionUserDefaultsWorker()
    let dataWorker: AttributionDataWorkerProtocol = AttributionDataWorker()
    let appTransactionIDProvider: AppTransactionIDProviderProtocol = AppTransactionIDProvider()
    
    var authorizationToken: AttributionServerToken!
    var facebookData: AttributionFacebookModel? = nil
    var appsflyerID: String? = nil
    var appEnvironment: String? = nil
    var shouldAwaitExternalAuth: Bool? = nil
        
    fileprivate func validateToken(_ token: AttributionServerToken?) -> Bool {
        guard authorizationToken != nil else {
            assertionFailure("TLMAnalyticsSender error: Auth token not found")
            return false
        }
        
        return true
    }
    
    fileprivate func validateInstallAttributed() -> String? {
        let savedUserIDOrNil = udefWorker.getServerUserID()
        return savedUserIDOrNil
    }
    
    fileprivate func collectInstallData() async -> AttributionInstallRequestModel {
        let attributionDetails:AttributionDetails? = await dataWorker.attributionDetails()
        
        let sdkVersion = dataWorker.sdkVersion
        let osVersion = dataWorker.osVersion
        let appVersion = dataWorker.appVersion
        let isTrackingEnabled = dataWorker.isAdTrackingEnabled
        let uuid = udefWorker.uuid
        let idfa = dataWorker.idfa
        let idfv = dataWorker.idfv
        let storeCountry = dataWorker.storeCountry
        
        var saFields: AttributionInstallRequestModel.SAFields?
        
        if let attributionDetails = attributionDetails {
            if let details = attributionDetails.details {
                saFields = AttributionInstallRequestModel.SAFields(data: details)
            }else{
                saFields = AttributionInstallRequestModel.SAFields(token: attributionDetails.attributionToken )
            }
        }
        
        var fbFields: AttributionInstallRequestModel.FBFields? = nil
        if let data = facebookData {
            fbFields = AttributionInstallRequestModel.FBFields(userId: data.fbUserId, userData: data.fbUserData, anonymousId: data.fbAnonId)
        }
        
        var status: UInt? = nil
        if #available(iOS 14.3, *) {
            status = ATTrackingManager.trackingAuthorizationStatus.rawValue
        }
        
        let parameters = AttributionInstallRequestModel(userId: uuid,
                                                        idfa: idfa,
                                                        idfv: idfv,
                                                        sdkVersion: sdkVersion,
                                                        osVersion: osVersion,
                                                        appVersion: appVersion,
                                                        limitAdTracking: !isTrackingEnabled,
                                                        storeCountry: storeCountry,
                                                        appsflyerId: appsflyerID,
                                                        iosATT: status,
                                                        environment: appEnvironment,
                                                        fb: fbFields, 
                                                        sa: saFields,
                                                        externalAuthorization: shouldAwaitExternalAuth)
        return parameters
    }
    
    fileprivate func getCorrectUUID() -> String {
        let result: String
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            if status == .authorized {
                let idfaOrNil = dataWorker.idfa
                let uuid = udefWorker.uuid
                result = idfaOrNil ?? uuid
            } else {
                if let savedGeneratedUUID = udefWorker.getGeneratedToken() {
                    result = savedGeneratedUUID
                } else {
                    let generatedUUID = dataWorker.generateUniqueToken()
                    udefWorker.saveGeneratedToken(generatedUUID)
                    
                    result = generatedUUID
                }
            }
        } else {
            let idfaOrNil = dataWorker.idfa
            let uuid = udefWorker.uuid
            result = idfaOrNil ?? uuid
        }
        
        return result
    }
}
 
extension AttributionServerManager {
    fileprivate func sendInstallData(_ data: AttributionInstallRequestModel, authToken: AttributionServerToken, completion: @escaping (AttributionManagerResult?) -> Void) {
        serverWorker?.sendInstallAnalytics(parameters: data,
                                           authToken: authorizationToken,
                                           isBackgroundSession: false)
        { (response, error) in
            self.handleSendInstallResponse(response, error: error, parameters: data, completion: completion)
        }
    }
    
    fileprivate func handleSendInstallResponse(_ response: [String: String]?, error: Error?,
                                               parameters: AttributionInstallRequestModel,
                                               completion: @escaping (AttributionManagerResult?) -> Void) {
        guard error == nil else {
            self.installError = error
            udefWorker.saveInstallData(parameters)
            completion(nil)
            return
        }
        
        guard let result = response, let uuid = result["uuid"] as? String else {
            self.installError = error
            udefWorker.saveInstallData(parameters)
            completion(nil)
            return
        }
        
        self.installError = nil
        
        var attributionToSend: [String: String]
        var isAB = false
        if let attribution = result as? [String: String] {
            attributionToSend = attribution
            attributionToSend.removeValue(forKey: "uuid")
            attributionToSend.removeValue(forKey: "isAB")
            isAB = ((attribution["isAB"] ?? "0") as NSString).boolValue
        } else {
            attributionToSend = [String: String]()
        }
        
        let idfv = result["idfv"] as? String
        let attrResult = AttributionManagerResult(userUUID: uuid, idfv: idfv,
                                              asaAttribution: attributionToSend, isIPAT: isAB)
        udefWorker.saveInstallResult(attrResult)
        completion(attrResult)
        udefWorker.saveServerUserID(uuid)
        udefWorker.deleteSavedInstallData()
        checkAndSendSavedPurchase(userId: uuid)
        checkAndSendAppTransaction()
        checkAndSendSavedExternalAuth(userId: uuid)
    }
}

extension AttributionServerManager {
    fileprivate func checkAndSendPurchase(_ details: AttributionPurchaseModel) {
        let userIdOrNil = udefWorker.getServerUserID()
        
        guard let userId = userIdOrNil else {
            self.udefWorker.savePurchaseData(details)
            syncOnAppStart { result in }
            return
        }
        
        formAndSendPurchase(userId: userId, details: details)
    }
    
    fileprivate func checkAndSendSavedPurchase(userId: String) {
        let savedDataOrNil = udefWorker.getPurchaseData()
        guard let savedData = savedDataOrNil else{
            return
        }
        
        formAndSendPurchase(userId: userId, details: savedData)
    }
    
    fileprivate func formAndSendPurchase(userId: String, details: AttributionPurchaseModel) {
        let subIdentifier = details.subscriptionIdentifier
        let price = details.price
        let introductoryPrice = details.introductoryPrice
        let currency = details.currencyCode
        let purchaseToken = dataWorker.receiptToken
        let jws = details.jws
        let originalTransactionID = details.originalTransactionID
        let decodedTransaction = details.decodedTransaction
        let uuid = udefWorker.uuid
        
        let introPrice = introductoryPrice ?? 0
        
        let anal = AttrubutionPurchaseRequestModel(productId: subIdentifier,
                                                           purchaseId: purchaseToken,
                                                           userId: uuid,
                                                           adid: userId,
                                                           version: 2,
                                                           signedTransaction: jws,
                                                           decodedTransaction: decodedTransaction,
                                                           originalTransactionID:originalTransactionID,
                                                           paymentDetails: AttrubutionPurchaseRequestModel.PaymentDetails(price: price,
                                                                                                                          introductoryPrice: introPrice,
                                                                                                                          currency: currency))
        
        serverWorker?.sendPurchaseAnalytics(analytics: anal,
                                           userId: userId,
                                           authToken: authorizationToken,
                                            isBackgroundSession: false)
        { (response) in
            self.handleSendPurchaseResult(response, details: details)
        }
    }

    fileprivate func checkAndSendAppTransaction() {
        guard udefWorker.getAppTransactionSent() == false else {
            return
        }

        guard udefWorker.getServerUserID() != nil else {
            return
        }

        guard let appsflyerId = appsflyerID, appsflyerId.isEmpty == false else {
            return
        }

        guard let authToken = authorizationToken else {
            return
        }

        Task { [weak self] in
            guard let self else { return }

            let appTransactionID = await self.appTransactionIDProvider.fetchAppTransactionID()
            
            switch appTransactionID {
            case .success(let appTransactionID):
                guard appTransactionID.isEmpty == false else {
                    return
                }
                
                let payload = AttributionAppTransactionRequestModel(appsflyerId: appsflyerId,
                                                                    appTransactionID: appTransactionID)

                self.serverWorker?.sendAppTransaction(parameters: payload,
                                                      authToken: authToken,
                                                      isBackgroundSession: false) { [weak self] success in
                    guard success else { return }
                    self?.udefWorker.saveAppTransactionSent(true)
                }
                
            default:
                return
            }
        }
    }
    
    fileprivate func handleSendPurchaseResult(_ result: Bool,
                                              details: AttributionPurchaseModel) {
        if result == true {
            udefWorker.deleteSavedPurchaseData()
        } else {
            udefWorker.savePurchaseData(details)
        }
        checkAndSendAppTransaction()
    }
}

extension AttributionServerManager {
    fileprivate func checkAndSendExternalAuth(_ externalAuthId: String, completion: ((Bool) -> Void)? = nil) {
        let userIdOrNil = udefWorker.getServerUserID()
        
        guard let userId = userIdOrNil else {
            self.udefWorker.saveExternalAuthData(externalAuthId)
            syncOnAppStart { result in
                completion?(result != nil)
            }
            return
        }
        
        formAndSendExternalAuth(userId: userId, externalAuthId: externalAuthId, completion: completion)
    }
    
    fileprivate func checkAndSendSavedExternalAuth(userId: String) {
        let savedDataOrNil = udefWorker.getExternalAuthData()
        guard let savedData = savedDataOrNil else {
            return
        }
        
        formAndSendExternalAuth(userId: userId, externalAuthId: savedData)
    }
    
    fileprivate func formAndSendExternalAuth(userId: String, externalAuthId: String, completion: ((Bool) -> Void)? = nil) {
        let uuid = udefWorker.uuid
        
        let parameters = AttributionExternalAuthRequestModel(userId: uuid, productUserId: externalAuthId)
        
        serverWorker?.sendExternalAuthorization(parameters: parameters,
                                               authToken: authorizationToken)
        { (result) in
            self.handleSendExternalAuthResult(result, externalAuthId: externalAuthId)
            completion?(result)
        }
    }
    
    fileprivate func handleSendExternalAuthResult(_ result: Bool, externalAuthId: String) {
        if result == true {
            udefWorker.deleteSavedExternalAuthData()
        } else {
            udefWorker.saveExternalAuthData(externalAuthId)
        }
    }
    
    fileprivate func sendFCMToken(userId: String, fcmToken: String, localization: String, completion: @escaping (Bool) -> Void) {
        let parameters = AttributionTokenRequestModel(userId: userId, fcmToken: fcmToken, localization: localization, environment: appEnvironment)
        
        serverWorker?.sendFCMToken(parameters: parameters,
                                   authToken: authorizationToken,
                                   isBackgroundSession: false) { success in
            if success {
                self.udefWorker.saveFCMToken(fcmToken)
            }
            completion(success)
        }
    }
    
    public func checkAndSendSavedFCMToken(fcmToken: String, userId: String, localization: String, completion: @escaping (FcmTokenUpdateResult) -> Void) {
        let savedToken = udefWorker.getFCMToken()
        if savedToken != fcmToken {
            sendFCMToken(userId: userId, fcmToken: fcmToken, localization: localization) { success in
                completion(success ? .updated : .failed)
            }
        }else{
            completion(.notRequired)
        }
    }
}
