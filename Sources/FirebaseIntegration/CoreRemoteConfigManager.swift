//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 15/4/24.
//

import Foundation

#if !COCOAPODS
import Experiment
#else
import AmplitudeExperiment
#endif

public class CoreRemoteConfigManager {
    public private(set) var remoteConfigResult: [String: String]? = nil
    public private(set) var internalConfigResult: [String: String]? = nil
    public private(set) var install_server_path: String? = nil
    public private(set) var purchase_server_path: String? = nil

    private var remoteConfigManager: RemoteConfigManager
    
    private var isConfigured:Bool = false
    private var isConfigFetched:Bool = false
     
    public init(cnConfig: Bool, deploymentKey: String) {
        if cnConfig {
            remoteConfigManager = AmplitudeExperimentManager(deploymentKey: deploymentKey)
        } else {
            remoteConfigManager = FirebaseManager()
        }
    }
    
    public func configure(userID: String, completion: @escaping () -> Void) {
        guard !isConfigured else {
            return
        }
        
        remoteConfigManager.configure(id: userID) { [weak self] in
            self?.isConfigured = true
            completion()
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
    
    public func updateConfig(_ appConfigurables: [FirebaseConfigurable]) {
        guard !isConfigFetched else {
            return
        }
        
        remoteConfigManager.updateConfig(appConfigurables)
        
        remoteConfigResult = remoteConfigManager.remoteConfigResult
        internalConfigResult = remoteConfigManager.internalConfigResult
        install_server_path = remoteConfigManager.install_server_path
        purchase_server_path = remoteConfigManager.purchase_server_path
    }
}
