import Foundation
import AdSupport
import AdServices
import AppTrackingTransparency

extension AttributionServerManager: AttributionServerManagerProtocol {
    public var savedUserUUID: String? {
        return udefWorker.getServerUserID()
    }
    
    public var installResultData: AttributionManagerResult? {
        return udefWorker.getInstallResult()
    }
    
    public func configure(config: AttributionConfigData) {
        self.facebookData = config.facebookData
        self.appsflyerID = config.appsflyerID
        authorizationToken = config.authToken
        
        serverWorker = AttributionServerWorker(installServerURLPath: config.installServerURLPath,
                                                       purchaseServerURLPath: config.purchaseServerURLPath,
                                                       installPath: config.installPath,
                                                       purchasePath: config.purchasePath)
    }
    
    public func configureURLs(config: AttributionConfigURLs) {
        serverWorker = AttributionServerWorker(installServerURLPath: config.installServerURLPath,
                                               purchaseServerURLPath: config.purchaseServerURLPath,
                                               installPath: config.installPath,
                                               purchasePath: config.purchasePath)
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
        
        checkAndSendSavedPurchase(userId: userID)
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
}

open class AttributionServerManager {
    public static var shared: AttributionServerManager = AttributionServerManager()
    public var uniqueUserID: String? {
        return udefWorker.uuid
    }
    
    var serverWorker: AttributionServerWorkerProtocol?
    let udefWorker: AttributionUserDefaultsWorkerProtocol = AttributionUserDefaultsWorker()
    let dataWorker: AttributionDataWorkerProtocol = AttributionDataWorker()
    
    var authorizationToken: AttributionServerToken!
    var facebookData: AttributionFacebookModel? = nil
    var appsflyerID: String? = nil
        
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
                                                            fb: fbFields, sa: saFields)
            return parameters
        }
    
    fileprivate func sendInstallData(_ data: AttributionInstallRequestModel, authToken: AttributionServerToken, completion: @escaping (AttributionManagerResult?) -> Void) {
        serverWorker?.sendInstallAnalytics(parameters: data,
                                          authToken: authorizationToken)
        { (response) in
            self.handleSendInstallResponse(response, parameters: data, completion: completion)
        }
    }
    
    fileprivate func checkAndSendPurchase(_ details: AttributionPurchaseModel) {
        let userIdOrNil = udefWorker.getServerUserID()
        
        guard let userId = userIdOrNil else {
            self.udefWorker.savePurchaseData(details)
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
                                           authToken: authorizationToken)
        { (response) in
            self.handleSendPurchaseResult(response, details: details)
        }
    }
    
    fileprivate func handleSendInstallResponse(_ response: [String: String]?,
                                               parameters: AttributionInstallRequestModel,
                                               completion: @escaping (AttributionManagerResult?) -> Void) {
        if let result = response, let uuid = result["uuid"] as? String {
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
            let result = AttributionManagerResult(userUUID: uuid, idfv: idfv,
                                                  asaAttribution: attributionToSend, isIPAT: isAB)
            udefWorker.saveInstallResult(result)
            completion(result)
            udefWorker.saveServerUserID(uuid)
            udefWorker.deleteSavedInstallData()
            checkAndSendSavedPurchase(userId: uuid)
        } else {
            udefWorker.saveInstallData(parameters)
            completion(nil)
        }
    }
    
    fileprivate func handleSendPurchaseResult(_ result: Bool,
                                              details: AttributionPurchaseModel) {
        if result == true {
            udefWorker.deleteSavedPurchaseData()
        } else {
            udefWorker.savePurchaseData(details)
        }
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
