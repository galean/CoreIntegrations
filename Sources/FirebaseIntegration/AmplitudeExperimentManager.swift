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
    public private(set) var install_server_path: String? = nil
    public private(set) var purchase_server_path: String? = nil
    
    init(deploymentKey: String) {
        let builder = ExperimentConfigBuilder()
        builder.automaticExposureTracking(false)
        
        let config = builder.build()
        
        client = Experiment.initializeWithAmplitudeAnalytics(
            apiKey: deploymentKey,
            config: config
        )
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
        
        let installPayload = client.variant(self.kInstallURL).payload as? String
        let installValue = client.variant(self.kInstallURL).value
        let purchasePayload = client.variant(self.kPurchaseURL).payload as? String
        let purchaseValue = client.variant(self.kPurchaseURL).value
        
        self.install_server_path = installPayload ?? installValue ?? ""
        self.purchase_server_path = purchasePayload ?? purchaseValue ?? ""
        
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
    public func configure(id: String, completion: @escaping () -> Void) {
        client.start(nil) { error in
            completion()
        }
    }
    
    public func fetchRemoteConfig(_ appConfigurables: [any FirebaseConfigurable], completion: @escaping () -> Void) {
        client.fetch(user: nil) { client, error in
            guard error == nil else {
                completion()
                return
            }
            
            self.internalUpdateConfig(client: client, appConfigurables: appConfigurables)
            
            completion()
        }
    }
    
    public func updateConfig(_ appConfigurables: [FirebaseConfigurable]) {
        internalUpdateConfig(client: client, appConfigurables: appConfigurables)
    }
}
