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
    
    init(deploymentKey: String) {
        client = Experiment.initializeWithAmplitudeAnalytics(
            apiKey: deploymentKey,
            config: ExperimentConfigBuilder().build()
        )
    }
    
    func configure(completion: @escaping () -> Void) {
        client.start(nil) { error in
            completion()
            let variant = self.client.variant("test_flag")
            let var2 = self.client.variant("test_paywall_name")
            print(variant)
            print(var2)
            if variant.value == "on" {
                // Flag is on
            } else {
                // Flag is off
            }
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
            
            self.internalConfigResult = client.all().reduce(into: [String:String](), { partialResult, variantWithKey in
                if let value = variantWithKey.value.value, value != "" {
                    partialResult[variantWithKey.key] = value
                }
            })
            self.remoteConfigResult = configResult
            completion()
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now()+5.0) { [weak self] in
            print("EXPERIMENT: test_flag: \(self?.client.variant("test_local_adv"))")
            print("EXPERIMENT: test_flag RESULT: \(self?.client.variant("test_local_adv").value)")
        }
    }
}
