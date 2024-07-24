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
        }
        
        
    }
    
    public func getAllVariants() -> [String: Variant] {
        return client.all()
    }
    
    public func getValue(key: String) -> String {
        return client.variant(key).value ?? ""
    }
    
    public func getValueWithFetching(key:String, completion: @escaping (_ value:String) -> Void) {
        client.fetch(user: nil) { client, error in
            completion(client.variant(key).value ?? "")
        }
    }
    
    public func fetchRemoteConfig(completion: @escaping (_ variants: [String: Variant]) -> Void) {
        client.fetch(user: nil) { client, error in
            completion(client.all())
        }
    }
}
