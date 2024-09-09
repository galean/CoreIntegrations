//
//  File.swift
//  
//
//  Created by Anzhy on 17.07.2024.
//

import Foundation

#if !COCOAPODS
import Experiment
#else
import AmplitudeExperiment
#endif

public class AmplitudeExperimentManager {
    let client: ExperimentClient
    
    public private(set) var remoteConfigResult: [String: String]? = nil
    public private(set) var internalConfigResult: [String: String]? = nil
    public private(set) var install_server_path: String?
    public private(set) var purchase_server_path: String?
    public var amplitudeOn: Bool { return true }
    
    var configured = false
    var configurationCompletion: (() -> Void)? = nil
    
    var fetched = false
    var savedConfigurables: [any FirebaseConfigurable]? = nil
    var fetchCompletion: (() -> Void)? = nil

    init(deploymentKey: String) {
        let builder = ExperimentConfigBuilder()
        builder.automaticExposureTracking(false)
        
        let config = builder.build()
        
        client = Experiment.initializeWithAmplitudeAnalytics(
            apiKey: deploymentKey,
            config: config
        )
        
        client.start(nil) { error in
            self.configured = true
            self.configurationCompletion?()
            
            self.client.fetch(user: nil) { [weak self] client, error in
                guard error == nil else {
                    self?.fetchCompletion?()
                    return
                }
                
                if let fetchCompletion = self?.fetchCompletion, let savedConfigurables = self?.savedConfigurables {
                    self?.internalUpdateConfig(client: client, appConfigurables: savedConfigurables)
                    fetchCompletion()
                }
            }
        }
    }
    
    func internalUpdateConfig(client: ExperimentClient, appConfigurables: [FirebaseConfigurable]) {
        let allKeys = appConfigurables.map { $0.key }
        let configResult = allKeys.reduce(into: [String: String]()) { partialResult, key in
            let configValue = client.variant(key).value ?? ""
            let configPayload = client.variant(key).payload as? [String: String]
            if let configPayload, let payloadValue = configPayload.first?.value {
                partialResult[key] = payloadValue
            } else if configValue != "" {
                partialResult[key] = configValue
            }
        }
        
        let installPayload = client.variant(self.kInstallURL).payload as? [String: String]
        let installPayloadValue = installPayload?.first?.value
        let installValue = client.variant(self.kInstallURL).value
        install_server_path = installPayloadValue ?? installValue ?? ""
        
        let purchasePayload = client.variant(self.kPurchaseURL).payload as? [String: String]
        let purchasePayloadValue = purchasePayload?.first?.value
        let purchaseValue = client.variant(self.kPurchaseURL).value
        purchase_server_path = purchasePayloadValue ?? purchaseValue ?? ""
        
        self.internalConfigResult = client.all().reduce(into: [String:String](), { partialResult, variantWithKey in
            let configValue = variantWithKey.value.value ?? ""
            let configPayload = variantWithKey.value.payload as? [String: String]
            if let configPayload, let payloadValue = configPayload.first?.value {
                partialResult[variantWithKey.key] = payloadValue
            } else if configValue != "" {
                partialResult[variantWithKey.key] = configValue
            }
            
        })
        
        self.remoteConfigResult = configResult
    }
}

extension AmplitudeExperimentManager: RemoteConfigManager {
    public func getValue(forConfig config: FirebaseConfigurable) -> String? {
        return client.variant(config.key).value
    }
    
    public func updateValue(forConfig config: FirebaseConfigurable, newValue: String?) {
        //nothing to do here
    }
    
    public func configure(id: String, completion: @escaping () -> Void) {
        if configured {
            completion()
        }else {
            self.configurationCompletion = completion
        }
    }
    
    public func fetchRemoteConfig(_ appConfigurables: [any FirebaseConfigurable], completion: @escaping () -> Void) {
        if fetched {
            self.internalUpdateConfig(client: client, appConfigurables: appConfigurables)
            completion()
        } else {
            self.fetchCompletion = completion
        }
    }
}
