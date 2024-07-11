//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 15/4/24.
//

import Foundation
import GrowthBook

public protocol GrowthBookDebugDelegate: AnyObject {
    func trackingCallbackResult(experimentInfo: String, resultInfo: String)
    func refreshHandlerResult(result: Bool)
    func configTimeout()
    func configurationFinished()
    func fetchedRemoteConfig(configResult: [String: String], featuresInfo: [String])
}

public class GrowthBookManager {
    public private(set) var remoteConfigResult: [String: String]? = nil
    public private(set) var internalConfigResult: [String: String]? = nil
    public private(set) var install_server_path: String? = nil
    public private(set) var purchase_server_path: String? = nil
    
    private let kInstallURL = "install_server_path"
    private let kPurchaseURL = "purchase_server_path"
    
    private var privateInstance:GrowthBookSDK?
    
    private var debugDelegate: GrowthBookDebugDelegate?
    
    public init() { }
    
    public func configure(id:String, clientKey:String, debugDelegate: GrowthBookDebugDelegate?, completion: @escaping () -> Void) {
        self.debugDelegate = debugDelegate
        let attrs = [ "id":id ]
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let sdkInstance = GrowthBookBuilder(apiHost: "https://cdn.growthbook.io", clientKey: clientKey, encryptionKey: nil, attributes: attrs, trackingCallback: { experiment, result in
            debugDelegate?.trackingCallbackResult(experimentInfo: experiment.debugDescription, resultInfo: result.debugDescription)
            semaphore.signal()
        }, refreshHandler: { handler in
            debugDelegate?.refreshHandlerResult(result: handler)
            if handler {
                semaphore.signal()
            }
        })
            .setLogLevel(.warning)
            .initializer()
        
        privateInstance = sdkInstance
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
            debugDelegate?.configTimeout()
            semaphore.signal()
        }
        
        semaphore.wait()
        
        debugDelegate?.configurationFinished()
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
        
        let features = getFeatures()
        var featuresInfo: [String] = []
        features.forEach { (key: String, value: Feature) in
            featuresInfo.append(value.debugDescription)
        }
        
        let keys = features.keys

        
        self.internalConfigResult = keys.reduce(into: [String:String](), { partialResult, key in
            let configValue = getStringValue(for: key)
            if configValue != "" {
                partialResult[key] = configValue
            }
        })
        
        self.remoteConfigResult = configResult
        debugDelegate?.fetchedRemoteConfig(configResult: configResult, featuresInfo: featuresInfo)
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
