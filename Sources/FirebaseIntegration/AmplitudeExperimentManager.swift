//
//  File.swift
//  
//
//  Created by Anzhy on 17.07.2024.
//

import Foundation
import Experiment

public class AmplitudeExperimentManager {
    let client: ExperimentClient
    
    public private(set) var remoteConfigResult: [String: String]? = nil
    public private(set) var internalConfigResult: [String: String]? = nil
    public private(set) var install_server_path: String? = nil
    public private(set) var purchase_server_path: String? = nil
    
    init(deploymentKey: String) {
        client = Experiment.initializeWithAmplitudeAnalytics(
            apiKey: deploymentKey,
            config: ExperimentConfigBuilder().build()
        )
    }
    
    func internalUpdateConfig(client: ExperimentClient, appConfigurables: [FirebaseConfigurable]) {
        let allKeys = appConfigurables.map { $0.key }
        let configResult = allKeys.reduce(into: [String: String]()) { partialResult, key in
            let configValue = client.variant(key).value ?? ""
            if configValue != "" {
                partialResult[key] = configValue
            }
        }
        
        self.install_server_path = client.variant(self.kInstallURL).value ?? ""
        self.purchase_server_path = client.variant(self.kPurchaseURL).value ?? ""
        
        self.internalConfigResult = client.all().reduce(into: [String:String](), { partialResult, variantWithKey in
            let configValue = variantWithKey.value.value ?? ""
            if configValue != "" {
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
