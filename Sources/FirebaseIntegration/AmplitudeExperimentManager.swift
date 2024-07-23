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
    
    init(apiKey: String) {
        client = Experiment.initializeWithAmplitudeAnalytics(
            apiKey: apiKey,
            config: ExperimentConfigBuilder().build()
        )
    }
    
    func configure(completion: @escaping () -> Void) {
        client.start(nil) { error in
            completion()
        }
    }
    
    public func fetchRemoteConfig(_ appConfigurables: [any FirebaseConfigurable], completion: @escaping () -> Void) {
        client.fetch(user: nil) { client, error in
            let configResult = appConfigurables.reduce(into: [String: String]()) { partialResult, configurable in
                let variantToDebug = client.variant(configurable.key)
                let variant = client.variant(configurable.key, fallback: Variant(configurable.defaultValue))
                if let value = variant.value, value != "" {
                    partialResult[configurable.key] = value
                }
            }
            
//            let allVariants = client.all()
            
            appConfigurables.forEach { configurable in
                let variant = client.variant(configurable.key)
                
//                let foundVariant = allVariants.first{ $0.key == configurable.key }
//                let result = foun
            }
            
            /*
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
             */
        }
    }
}
