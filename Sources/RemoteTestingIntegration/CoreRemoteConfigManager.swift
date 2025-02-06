
import Foundation

#if !COCOAPODS
import Experiment
#else
import AmplitudeExperiment
#endif

public class CoreRemoteConfigManager: RemoteConfigManager {
    private var remoteConfigManager: RemoteConfigManager
    
    private var isConfigFetched:Bool = false
    
    public var allRemoteValues: [String: String] {
        remoteConfigManager.allRemoteValues
    }
     
    public init(deploymentKey: String) {
        remoteConfigManager = AmplitudeExperimentManager(deploymentKey: deploymentKey)
    }
    
    public func fetchRemoteConfig(_ appConfigurables: [any RemoteConfigurable], completion: @escaping () -> Void) {
        guard !isConfigFetched else {
            completion()
            return
        }
        
        remoteConfigManager.fetchRemoteConfig(appConfigurables) { [weak self] in
            guard let self = self else {return}

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
}
