
import Foundation

class AttributionUserDefaultsWorker: AttributionUserDefaultsWorkerProtocol {
    let userDefaults = UserDefaults.standard
    
    fileprivate let installDataKey = "ANALYTICS_DATA_TO_SAVE"
    fileprivate let serverUserIDKey = "ANALYTICS_USER_ID"
    fileprivate let purchaseDataKey = "ANALYTICS_PURCHASE_DATA"
    fileprivate let userTokenKey = "ANALYTICS_USER_TOKEN"
    fileprivate let installResult = "ANALYTICS_INSTALL_RESULT"
    
    func getInstallData() -> AttributionInstallRequestModel? {
        let dataOrNil = userDefaults.object(forKey: installDataKey) as? Data
        
        guard let data = dataOrNil else {
            return nil
        }
        
        let analytics = try? JSONDecoder().decode(AttributionInstallRequestModel.self, from: data)
        return analytics
    }
    
    func saveInstallData(_ data: AttributionInstallRequestModel) {
        let jsonDataOrNil = try? JSONEncoder().encode(data)
        
        guard let jsonData = jsonDataOrNil else {
            print("\n\n\nANALYTICS IS NOT SAVED\n\n\n")
            return
        }
        
        userDefaults.set(jsonData, forKey: installDataKey)
        userDefaults.synchronize()
    }
    
    func getInstallResult() -> AttributionManagerResult? {
        return userDefaults.value(AttributionManagerResult.self, forKey: installResult)
    }
    
    func saveInstallResult(_ result: AttributionManagerResult?) {
        userDefaults.set(encodable: result, forKey: installResult)
        userDefaults.synchronize()
    }
    
    func getUserToken() -> String? {
        return userDefaults.string(forKey: userTokenKey)
    }
    
    func saveUserToken(_ token: String) {
        userDefaults.set(token, forKey: userTokenKey)
        userDefaults.synchronize()
    }
    
    func getPurchaseData() -> AttributionPurchaseModel? {
        let dataOrNil = userDefaults.object(forKey: purchaseDataKey) as? Data
        
        guard let data = dataOrNil else {
            return nil
        }
        
        let analytics = try? JSONDecoder().decode(AttributionPurchaseModel.self, from: data)
        return analytics
    }
    
    func savePurchaseData(_ data: AttributionPurchaseModel) {
        let jsonDataOrNil = try? JSONEncoder().encode(data)
        
        guard let jsonData = jsonDataOrNil else {
            print("\n\n\nANALYTICS IS NOT SAVED\n\n\n")
            return
        }
        
        userDefaults.set(jsonData, forKey: purchaseDataKey)
        userDefaults.synchronize()
    }
    
    func getServerUserID() -> String? {
        return userDefaults.string(forKey: serverUserIDKey)
    }
    
    func saveServerUserID(_ id: String) {
        userDefaults.set(id, forKey: serverUserIDKey)
        userDefaults.synchronize()
    }
    
    func deleteSavedInstallData() {
        userDefaults.removeObject(forKey: installDataKey)
        userDefaults.synchronize()
    }
    
    func deleteSavedPurchaseData() {
        userDefaults.removeObject(forKey: purchaseDataKey)
        userDefaults.synchronize()
    }
}

@propertyWrapper struct UserDefaultAccess<T: Codable> {
    let key: String
    let defaultValue: T
    let userDefaults: UserDefaultsService

    init(
        key: String,
        defaultValue: T,
        userDefaults: UserDefaultsService = UserDefaults.standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    var wrappedValue: T {
        get {
            return userDefaults.value(T.self, forKey: key) ?? defaultValue
        }
        set {
            userDefaults.set(encodable: newValue, forKey: key)
        }
    }
}

protocol UserDefaultsService {
    func set<T: Encodable>(encodable: T, forKey key: String)
    func value<T: Decodable>(_ type: T.Type, forKey key: String) -> T?
}

extension UserDefaults: UserDefaultsService {
    func set<T: Encodable>(encodable: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(encodable) {
            set(data, forKey: key)
        }
    }

    func value<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        if let data = object(forKey: key) as? Data,
            let value = try? JSONDecoder().decode(type, from: data) {
            return value
        }
        return nil
    }
}
