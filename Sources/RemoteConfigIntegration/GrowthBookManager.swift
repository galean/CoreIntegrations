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
    
    private var privateInstance:GrowthBookSDK?
    private let configuration: GrowthBookConfiguration
    
    private var debugDelegate: GrowthBookDebugDelegate?
    
    public init(growthBookConfig: GrowthBookConfiguration, debugDelegate: GrowthBookDebugDelegate?) {
        configuration = growthBookConfig
        self.debugDelegate = debugDelegate
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
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        return version
    }
}

extension GrowthBookManager: RemoteConfigManager {
    public func configure(id: String, completion: @escaping () -> Void) {
        let attrs = [ "id": id ]
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let sdkInstance = GrowthBookBuilder(apiHost: configuration.hostURL, clientKey: configuration.clientKey,
                                            encryptionKey: nil, attributes: attrs, trackingCallback: { experiment, result in
            self.debugDelegate?.trackingCallbackResult(experimentInfo: experiment.debugDescription, resultInfo: result.debugDescription)
            semaphore.signal()
        }, refreshHandler: { handler in
            self.debugDelegate?.refreshHandlerResult(result: handler)
            if handler {
                semaphore.signal()
            }
        })
            .setLogLevel(.warning)
            .initializer()
        
        privateInstance = sdkInstance
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
            self.debugDelegate?.configTimeout()
            semaphore.signal()
        }
        
        semaphore.wait()
        
        self.debugDelegate?.configurationFinished()
        completion()
    }
    
    public func setUserID(_ id: String) {
        privateInstance?.setAttributes(attributes: ["id":id, "App version": appVersion])
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
            let ruleCount = value.rules?.count ?? 0
            let rule = value.rules?.first?.variations?.description ?? ""
            let condition = value.rules?.first?.condition?.string ?? ""
            featuresInfo.append("key: \(key), defaultInfo: \(value.defaultValue?.stringValue ?? ""), ruleInfo: { ruleCount: \(ruleCount), ruleVariations: \(rule), condition: \(condition) }")
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
}
