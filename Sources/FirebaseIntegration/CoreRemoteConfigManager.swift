//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 15/4/24.
//

import Foundation

public class CoreRemoteConfigManager {
    public private(set) var remoteConfigResult: [String: String]? = nil
    public private(set) var internalConfigResult: [String: String]? = nil
    public private(set) var install_server_path: String? = nil
    public private(set) var purchase_server_path: String? = nil
    
    private let kInstallURL = "install_server_path"
    private let kPurchaseURL = "purchase_server_path"
    
    private let firebaseManager = FirebaseManager()
    private let growthBookManager = GrowthBookManager()
    private let amplExperimentManager: AmplitudeExperimentManager
    private var mainConfigConfigured = false
    private var amplConfigured = false
    private var isConfigured = false
    private var isConfigFetched = false
    
    private let cnConfig: Bool
    private var growthBookKey:String?
    
    public init(cnConfig: Bool, growthBookClientKey:String?, deploymentKey: String) {
        self.cnConfig = cnConfig
        self.growthBookKey = growthBookClientKey
        amplExperimentManager = AmplitudeExperimentManager(deploymentKey: deploymentKey)
    }
    
    public func configure(id:String, completion: @escaping () -> Void) {
        guard !isConfigured else {
            return
        }
        
        if cnConfig, let growthBookClientKey = growthBookKey {
            growthBookManager.configure(id: id, clientKey: growthBookClientKey) { [weak self] in
                self?.mainConfigConfigured = true
                if self?.amplConfigured == true {
                    completion()
                    self?.isConfigured = true
                }
            }
        }else{
            firebaseManager.configure() { [weak self] in
                self?.firebaseManager.setUserID(id)
                self?.mainConfigConfigured = true
                if self?.amplConfigured == true {
                    completion()
                    self?.isConfigured = true
                }
            }
        }
        amplExperimentManager.configure { [weak self] in
            self?.amplConfigured = true
            if self?.mainConfigConfigured == true {
                completion()
                self?.isConfigured = true
            }
        }
    }
    
    public func fetchRemoteConfig(_ appConfigurables: [any FirebaseConfigurable], completion: @escaping () -> Void) {
        guard !isConfigFetched else {
            completion()
            return
        }
        if cnConfig, let growthBookClientKey = growthBookKey {
            growthBookManager.fetchRemoteConfig(appConfigurables) { [weak self] in
                guard let self = self else {return}
                
                remoteConfigResult = growthBookManager.remoteConfigResult
                internalConfigResult = growthBookManager.internalConfigResult
                
                install_server_path = growthBookManager.install_server_path
                purchase_server_path = growthBookManager.purchase_server_path
                
                isConfigFetched = true
                completion()
            }
        }else{
            firebaseManager.fetchRemoteConfig(appConfigurables) { [weak self] in
                guard let self = self else {return}
                
                remoteConfigResult = firebaseManager.remoteConfigResult
                internalConfigResult = firebaseManager.internalConfigResult
                
                install_server_path = firebaseManager.install_server_path
                purchase_server_path = firebaseManager.purchase_server_path
                
                isConfigFetched = true
                completion()
            }
        }
        amplExperimentManager.fetchRemoteConfig(appConfigurables) { [weak self] in
            guard let self = self else {return}
            
            print(amplExperimentManager.internalConfigResult)
            print(amplExperimentManager.remoteConfigResult)
        }
    }
    
}
