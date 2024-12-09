
import Foundation

#if !COCOAPODS
import Experiment
#else
import AmplitudeExperiment
#endif

public class CoreRemoteConfigManager: RemoteConfigManager {
//    public private(set) var remoteConfigResult: [String: String]? = nil
//    public private(set) var internalConfigResult: [String: String]? = nil
//    public private(set) var install_server_path: String? = nil
//    public private(set) var purchase_server_path: String? = nil
//    public var amplitudeOn: Bool { return remoteConfigManager.amplitudeOn }

    private var remoteConfigManager: RemoteConfigManager
    
    private var isConfigured:Bool = false
    private var isConfigFetched:Bool = false
    
    public var allRemoteValues: [String: String] {
        remoteConfigManager.allRemoteValues
    }
     
    public init(deploymentKey: String) {
        remoteConfigManager = AmplitudeExperimentManager(deploymentKey: deploymentKey)
    }
    
    public func configure(id userID: String, completion: @escaping () -> Void) {
        guard !isConfigured else {
            return
        }
        
        remoteConfigManager.configure(id: userID) { [weak self] in
            self?.isConfigured = true
            completion()
        }
    }
    
    public func fetchRemoteConfig(_ appConfigurables: [any RemoteConfigurable], completion: @escaping () -> Void) {
        guard !isConfigFetched else {
            completion()
            return
        }
        
        remoteConfigManager.fetchRemoteConfig(appConfigurables) { [weak self] in
            guard let self = self else {return}
            
//            remoteConfigResult = remoteConfigManager.remoteConfigResult
//            internalConfigResult = remoteConfigManager.internalConfigResult
//            
//            install_server_path = remoteConfigManager.install_server_path
//            purchase_server_path = remoteConfigManager.purchase_server_path
            
            isConfigFetched = true
            completion()
        }
    }
    
    public func getValue(forConfig config: RemoteConfigurable) -> String? {
        return remoteConfigManager.getValue(forConfig: config)
    }
    
    public func exposure(forConfig config: RemoteConfigurable) {
        remoteConfigManager.exposure(forConfig: config)
    }
    
//    public func updateValue(forConfig config: RemoteConfigurable, newValue: String?) {
//        remoteConfigManager.updateValue(forConfig: config, newValue: newValue)
//    }
}
