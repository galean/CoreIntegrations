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
    
    private var privateInstance:GrowthBookSDK?
    private let configuration: GrowthBookConfiguration
    
    public init(growthBookConfig: GrowthBookConfiguration) {
        configuration = growthBookConfig
    }
    
    private func getFeatures() -> [String: GrowthBook.Feature] {
        guard let privateInstance = privateInstance else {
            assertionFailure()
            return [:]
        }
        return privateInstance.getFeatures()
    }
    
    private func getStringValue(for feature:String) -> String {
        guard let privateInstance = privateInstance else {
            assertionFailure()
            return ""
        }
        return privateInstance.getFeatureValue(feature: feature, default: "default").stringValue
    }
    
    private func getBoolValue(for feature:String) -> Bool {
        guard let privateInstance = privateInstance else {
            assertionFailure()
            return false
        }
        return privateInstance.getFeatureValue(feature: feature, default: "default").boolValue
    }
    
}

extension GrowthBookManager: RemoteConfigManager {
    public func configure(id: String, completion: @escaping () -> Void) {
        let attrs = [ "id": id ]
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let sdkInstance = GrowthBookBuilder(apiHost: configuration.hostURL, clientKey: configuration.clientKey,
                                            encryptionKey: nil, attributes: attrs, trackingCallback: { experiment, result in
            semaphore.signal()
        }, refreshHandler: { handler in
            if handler {
                semaphore.signal()
            }
        })
            .setLogLevel(.debug)
            .initializer()
        
        privateInstance = sdkInstance
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
            semaphore.signal()
        }
        
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
}
