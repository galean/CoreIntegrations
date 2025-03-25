import Foundation

#if !COCOAPODS
import Experiment
import RemoteTestingIntegration
#else
import AmplitudeExperiment
#endif

public protocol ExtendedRemoteConfigurable: RemoteConfigurable {
    var boolValue: Bool { get }
    func updateValue(_ newValue: String?)
}

public extension ExtendedRemoteConfigurable {
    var value: String {
        get {
            if stickyBucketed {
                if stickyBuckettedValue == nil {
                    setStickyBuckettedValue(with: remoteValue)
                }
            } else {
                setStickyBuckettedValue(with: nil)
            }
            
            let value = internalValue
            
            if lastExposedValue != value {
                setLastExposedValue(newValue: value)
                exposure()
            }
            
            return internalValue
        }
    }
    
    func updateValue(_ newValue: String?) {
        setManualReassignValue(with: newValue)
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

extension ExtendedRemoteConfigurable {
    private func updateInternalValue(_ newValue: String?) {
        setInternalManualReassignValue(with: newValue)
    }
    
    private func exposure() {
        guard let configManager = CoreManager.internalShared.remoteConfigManager else {
            return
        }
        
        configManager.exposure(forConfig: self)
    }
}

extension ExtendedRemoteConfigurable {
    private var internalValue: String {
        get {
            if let _ = ProcessInfo.processInfo.environment["xctest_skip_config"] {
                return manualReassignedValue ?? defaultValue
            }
            
            return manualReassignedValue ?? internalReassignedValue ?? stickyBuckettedValue ?? remoteValue
        }
    }
    
    private var remoteValue: String {
        guard let configManager = CoreManager.internalShared.remoteConfigManager else {
            return defaultValue
        }
        
        return configManager.getValue(forConfig: self) ?? defaultValue
    }
}

extension ExtendedRemoteConfigurable {
    private var manualReassignedValue: String? {
        let savedValue = UserDefaults.standard.object(forKey: key) as? String
        return savedValue
    }
    
    private func setManualReassignValue(with newValue: String?) {
        UserDefaults.standard.setValue(newValue, forKey: key)
    }
}

extension ExtendedRemoteConfigurable {
    private func setStickyBuckettedValue(with newValue: String?) {
        guard let newValue else {
            UserDefaults.standard.removeObject(forKey: "sticky_"+key)
            return
        }
        UserDefaults.standard.setValue(newValue, forKey: "sticky_"+key)
    }
    
    private var stickyBuckettedValue: String? {
        let savedValue = UserDefaults.standard.object(forKey: "sticky_"+key) as? String
        return savedValue
    }
}

extension ExtendedRemoteConfigurable {
    private var lastExposedValue: String? {
        let savedValue = UserDefaults.standard.object(forKey: "last_exposed_"+key) as? String
        return savedValue
    }
    
    private func setLastExposedValue(newValue: String?) {
        UserDefaults.standard.setValue(newValue, forKey: "last_exposed_"+key)
    }
}

// Not used in this version anymore, but must be for old versions support
extension ExtendedRemoteConfigurable {
    private var internalReassignedValue: String? {
        let savedValue = UserDefaults.standard.object(forKey: "internal"+key) as? String
        return savedValue
    }
    
    private func setInternalManualReassignValue(with newValue: String?) {
        UserDefaults.standard.setValue(newValue, forKey: "internal"+key)
    }
}
