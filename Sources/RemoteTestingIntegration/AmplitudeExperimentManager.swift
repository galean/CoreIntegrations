import Foundation

#if !COCOAPODS
import Experiment
#else
import AmplitudeExperiment
#endif

public class AmplitudeExperimentManager {
    let client: ExperimentClient
    
    var fetched = false
    var savedConfigurables: [any RemoteConfigurable]? = nil
    var fetchCompletion: (() -> Void)? = nil
    
    public var allRemoteValues = [String: String]()
    public var remoteError: Error?

    init(deploymentKey: String) {
        let builder = ExperimentConfigBuilder()
        builder.automaticExposureTracking(true)
        
        let config = builder.build()
        
        client = Experiment.initializeWithAmplitudeAnalytics(
            apiKey: deploymentKey,
            config: config
        )
        
        DispatchQueue.global().async {
            self.fetch(userProperties: nil, completion: nil)
        }
    }
    
    func fetch(userProperties: [String: Any]?, completion: (() -> Void)?) {
        var user: ExperimentUser? = nil
        
        if let userProperties {
            let builder = ExperimentUserBuilder()
            builder.userProperties(userProperties)

            user = builder.build()
        }
        
        client.fetch(user: user) { client, error in
            defer {
                self.fetchCompletion?()
                self.fetchCompletion = nil
                self.savedConfigurables = nil
                completion?()
            }
            
            self.fetched = true

            guard error == nil else {
                self.remoteError = error
                return
            }
            
            self.remoteError = nil
            
            if let savedConfigurables = self.savedConfigurables {
                self.internalUpdateConfig(client: client, appConfigurables: savedConfigurables)
            }
        }
    }
    
    func internalUpdateConfig(client: ExperimentClient, appConfigurables: [RemoteConfigurable]) {
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
        
        allRemoteValues = configResult
    }
}

extension AmplitudeExperimentManager: RemoteConfigManager {
    public func getValue(forConfig config: RemoteConfigurable) -> String? {
        let payload = client.variant(config.key, fallback: Variant(config.defaultValue)).payload as? [String: String]
        let payloadValue = payload?.first?.value
        let value = client.variant(config.key, fallback: Variant(config.defaultValue)).value
        return payloadValue ?? value
    }
    
    public func exposure(forConfig config: RemoteConfigurable) {
        client.exposure(key: config.key)
    }
    
    public func updateRemoteConfig(_ userProperies: [String: String], completion: @escaping () -> Void) {
        self.fetch(userProperties: userProperies) {
            completion()
        }
    }
    
    public func configure(_ appConfigurables: [any RemoteConfigurable], completion: @escaping () -> Void) {
        if fetched {
            self.internalUpdateConfig(client: client, appConfigurables: appConfigurables)
            completion()
        } else {
            self.savedConfigurables = appConfigurables
            self.fetchCompletion = completion
        }
    }
}
