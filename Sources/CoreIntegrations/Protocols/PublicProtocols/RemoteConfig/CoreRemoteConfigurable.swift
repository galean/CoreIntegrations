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
    
    func updateValue(_ newValue: String?)
    func exposure()
}

public extension ExtendedRemoteConfigurable {
    var value: String {
        get {
            if let _ = ProcessInfo.processInfo.environment["xctest_skip_config"] {
                return reassignedValue ?? defaultValue
            }
            
            guard let configManager = CoreManager.internalShared.remoteConfigManager else {
                return defaultValue
            }
            
            return reassignedValue ?? internalReassignedValue ?? configManager.getValue(forConfig: self) ?? defaultValue
        }
    }
    
    private func manualReassignValue(with newValue: String?) {
        UserDefaults.standard.setValue(newValue, forKey: key)
    }
    
    private func internalManualReassignValue(with newValue: String?) {
        UserDefaults.standard.setValue(newValue, forKey: "internal"+key)
    }
    
    private var reassignedValue: String? {
        let savedValue = UserDefaults.standard.object(forKey: key) as? String
        return savedValue
    }
    
    private var internalReassignedValue: String? {
        let savedValue = UserDefaults.standard.object(forKey: "internal"+key) as? String
        return savedValue
    }
    
    func updateValue(_ newValue: String?) {
        manualReassignValue(with: newValue)
    }
    
    func updateInternalValue(_ newValue: String?) {
        internalManualReassignValue(with: newValue)
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
