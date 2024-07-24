//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 15/4/24.
//

import Foundation
import Experiment

public class CoreRemoteConfigManager {
    public private(set) var remoteConfigResult: [String: String]? = nil
    public private(set) var internalConfigResult: [String: String]? = nil
    public private(set) var install_server_path: String? = nil
    public private(set) var purchase_server_path: String? = nil
    
    public var amplitudeVariants: [String: Variant] {
        return amplExperimentManager.getAllVariants()
    }
    
    public func getValue(key: String) -> String {
        return amplExperimentManager.getValue(key: key)
    }
    
    public func getValueWithFetching(key:String, completion: @escaping (_ value:String) -> Void) {
        amplExperimentManager.getValueWithFetching(key: key, completion: completion)
    }

    private var remoteConfigManager: RemoteConfigManager
    
    private var isConfigured:Bool = false
    private var isConfigFetched:Bool = false
     
    private let amplExperimentManager: AmplitudeExperimentManager

    public init(cnConfig: Bool, growthBookConfig: GrowthBookConfiguration?, growthBookDebugDelegate: GrowthBookDebugDelegate?,
                deploymentKey: String) {
        if cnConfig, let growthBookConfig {
            remoteConfigManager = GrowthBookManager(growthBookConfig: growthBookConfig, debugDelegate: growthBookDebugDelegate)
        } else {
            remoteConfigManager = FirebaseManager()
        }
        amplExperimentManager = AmplitudeExperimentManager(deploymentKey: deploymentKey)
    }
    
    public func configure(userID: String, completion: @escaping () -> Void) {
        guard !isConfigured else {
            return
        }
        
        remoteConfigManager.configure(id: userID) { [weak self] in
            self?.isConfigured = true
            completion()
        }
        
        amplExperimentManager.configure { [weak self] in
            self?.amplExperimentManager.fetchRemoteConfig { [weak self] variants in
                guard let self = self else {return}
            }
        }
    }
    
    public func fetchRemoteConfig(_ appConfigurables: [any FirebaseConfigurable], completion: @escaping () -> Void) {
        guard !isConfigFetched else {
            completion()
            return
        }
        
        remoteConfigManager.fetchRemoteConfig(appConfigurables) { [weak self] in
            guard let self = self else {return}
            
            remoteConfigResult = remoteConfigManager.remoteConfigResult
            internalConfigResult = remoteConfigManager.internalConfigResult
            
            install_server_path = remoteConfigManager.install_server_path
            purchase_server_path = remoteConfigManager.purchase_server_path
            
            isConfigFetched = true
            completion()
        }
    }
}
