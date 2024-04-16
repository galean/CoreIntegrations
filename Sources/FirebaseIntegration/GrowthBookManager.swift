//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 15/4/24.
//

import Foundation
import GrowthBook

public class GrowthBookManager {
    public private(set) var remoteConfigResult: [String: String]? = nil
    public private(set) var internalConfigResult: [String: String]? = nil
    public private(set) var install_server_path: String? = nil
    public private(set) var purchase_server_path: String? = nil
    
    private let kInstallURL = "install_server_path"
    private let kPurchaseURL = "purchase_server_path"
    
    private var privateInstance:GrowthBookSDK?
    
    public init() { }
    
    public func configure(id:String, completion: @escaping () -> Void) {
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
        
        completion()
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
