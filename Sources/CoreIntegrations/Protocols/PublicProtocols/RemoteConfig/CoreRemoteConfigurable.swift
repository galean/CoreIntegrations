import Foundation

#if !COCOAPODS
import Experiment
import RemoteTestingIntegration
#else
import AmplitudeExperiment
#endif

public protocol CoreRemoteConfigurable: CaseIterable, ExtendedRemoteConfigurable {
    static var subscription_screen_style_full: Self { get }
    static var subscription_screen_style_h: Self { get }
    static var rate_us_primary_shown: Self { get }
    static var rate_us_secondary_shown: Self { get }
}

public protocol ExtendedRemoteConfigurable: RemoteConfigurable {
    var boolValue: Bool { get }
    var activeForSources: [CoreUserSource] { get }
    
    func updateValue(_ newValue: String)
    func exposure()
}

public extension ExtendedRemoteConfigurable {
    var value: String {
        get {
            guard let configManager = CoreManager.internalShared.remoteConfigManager else {
                return defaultValue
            }
            
            return reassignedValue ?? configManager.getValue(forConfig: self) ?? defaultValue
        }
    }
    
    private func manualReassignValue(with newValue: String) {
        UserDefaults.standard.setValue(newValue, forKey: key)
    }
    
    private var reassignedValue: String? {
        let savedValue = UserDefaults.standard.object(forKey: key) as? String
        return savedValue
    }
    
    func updateValue(_ newValue: String) {
        manualReassignValue(with: newValue)
    }
    
    func exposure() {
        guard let configManager = CoreManager.internalShared.remoteConfigManager else {
            return
        }
        
        configManager.exposure(forConfig: self)
    }
    
    var boolValue: Bool {
        get {
            switch self {
            default:
                let stringValue = value.replacingOccurrences(of: " ", with: "")
                switch stringValue {
                case "true", "1":
                    return true
                case "false", "0", "none":
                    return false
                default:
                    assertionFailure()
                    return false
                }
            }
        }
    }
}
