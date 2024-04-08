//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 19.07.2023.
//

import FirebaseAnalytics
import Firebase
import FirebaseRemoteConfig
import GrowthBook

public class FirebaseManager {
    public private(set) var remoteConfigResult: [String: String]? = nil
    public private(set) var internalConfigResult: [String: String]? = nil
    public private(set) var install_server_path: String? = nil
    public private(set) var purchase_server_path: String? = nil
    
    private let kInstallURL = "install_server_path"
    private let kPurchaseURL = "purchase_server_path"
    
    public init() {
        
    }
    
    public func configure() {
        FirebaseApp.configure()
        Analytics.logEvent("Firebase Init", parameters: nil)
    }
    
    public func setUserID(_ id: String) {
        Analytics.setUserID(id)
    }
    
    public func fetchRemoteConfig(_ appConfigurables: [any FirebaseConfigurable], completion: @escaping () -> Void) {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
//#if DEBUG
        settings.minimumFetchInterval = 0
//#else
//        settings.minimumFetchInterval = 1800
//#endif
        remoteConfig.configSettings = settings
        remoteConfig.fetchAndActivate { status, error in
            guard error == nil else {
                completion()
                return
            }
            
            let allKeys = appConfigurables.map { $0.key }
            let configResult = allKeys.reduce(into: [String: String]()) { partialResult, key in
                let configValue = remoteConfig.configValue(forKey: key).stringValue
                if configValue != nil && configValue != "" {
                    partialResult[key] = configValue
                }
            }
            
            self.install_server_path = remoteConfig.configValue(forKey: self.kInstallURL).stringValue
            self.purchase_server_path = remoteConfig.configValue(forKey: self.kPurchaseURL).stringValue
            
            self.internalConfigResult = remoteConfig.keys(withPrefix: "").reduce(into: [String:String](), { partialResult, key in
                let configValue = remoteConfig.configValue(forKey: key).stringValue
                if configValue != nil && configValue != "" {
                    partialResult[key] = configValue
                }
            })
            
            self.remoteConfigResult = configResult
            completion()
        }
    }
}



public class GrowthBookManager {
    public private(set) var remoteConfigResult: [String: String]? = nil
    public private(set) var internalConfigResult: [String: String]? = nil
    public private(set) var install_server_path: String? = nil
    public private(set) var purchase_server_path: String? = nil
    
    private let kInstallURL = "install_server_path"
    private let kPurchaseURL = "purchase_server_path"
    
    private var privateInstance:GrowthBookSDK?
    
    public init() {
        
    }
    
    public func configure(id:String) {
        let attrs = [ "id":id ]
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let sdkInstance = GrowthBookBuilder(apiHost: "https://cdn.growthbook.io", clientKey: "sdk-QcyY2yKqDGjEW3k", encryptionKey: nil, attributes: attrs, trackingCallback: { experiment, result in
            print("Viewed Experiment")
            print("Experiment Id: ", experiment.key)//ab_paywall_organic
            print("Variation Id: ", result.value)//2box or none_2box
            semaphore.signal()
        }, refreshHandler: { handler in
            print("refreshHandler \(handler)")
            semaphore.signal()
        }, backgroundSync: true)
            .setLogLevel(.trace)
            .initializer()
        
        privateInstance = sdkInstance
        semaphore.wait()
    }
    
    public func setUserID(_ id: String) {
        privateInstance?.setAttributes(attributes: ["id":id])
    }
    
    public func fetchRemoteConfig(_ appConfigurables: [any FirebaseConfigurable], completion: @escaping () -> Void) {
        let allKeys = appConfigurables.map { $0.key }
        let configResult = allKeys.reduce(into: [String: String]()) { partialResult, key in
            let configValue = getStringValue(for: key)
            if configValue != "" {
                partialResult[key] = configValue
            }
        }
        
        self.install_server_path = getStringValue(for: self.kInstallURL)
        self.purchase_server_path = getStringValue(for: self.kPurchaseURL)
        
        let keys = getFeatures().keys
        self.internalConfigResult = keys.reduce(into: [String:String](), { partialResult, key in
            let configValue = getStringValue(for: key)
            if configValue != "" {
                partialResult[key] = configValue
            }
        })
        
        self.remoteConfigResult = configResult
        completion()
    }
    
    func getFeatures() -> [String: GrowthBook.Feature] {
        guard let privateInstance = privateInstance else {
            assertionFailure()
            return [:]
        }
        return privateInstance.getFeatures()
    }
    
    func getStringValue(for feature:String) -> String {
        guard let privateInstance = privateInstance else {
            assertionFailure()
            return ""
        }
        return privateInstance.getFeatureValue(feature: feature, default: "default").stringValue
    }
    
    func getBoolValue(for feature:String) -> Bool {
        guard let privateInstance = privateInstance else {
            assertionFailure()
            return false
        }
        return privateInstance.getFeatureValue(feature: feature, default: "default").boolValue
    }
    
}
