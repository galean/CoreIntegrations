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
    func updatePayload(_ newValue: [String: Any]?)
    /// Whether reading `value`, `payload` or `boolValue` sends the exposure event. Defaults to `true`.
    /// Return `false` to send it only with `trackExposure()`.
    var automaticExposureTracking: Bool { get }
}

public extension ExtendedRemoteConfigurable {
    var automaticExposureTracking: Bool {
        return true
    }
    
    var value: String {
        get {
            updateExposure()
            return internalValue
        }
    }
    
    func updateValue(_ newValue: String?) {
        setManualReassignValue(with: newValue)
    }
    
    var payload: [String : Any]? {
        updateExposure()
        return internalPayload
    }
    
    /// Sends the exposure event unless the current value has already been exposed.
    func trackExposure() {
        guard CoreManager.internalShared.remoteConfigManager != nil else {
            return
        }
        
        updateStickyBucketing()
        sendExposureIfNeeded()
    }
    
    private func updateExposure() {
        updateStickyBucketing()
        
        if automaticExposureTracking {
            sendExposureIfNeeded()
        }
    }
    
    private func updateStickyBucketing() {
        if stickyBucketed && stickyBuckettedValue == nil {
            setStickyBuckettedValue(with: remoteValue)
        } else if !stickyBucketed && stickyBuckettedValue != nil {
            setStickyBuckettedValue(with: nil)
        }
    }
    
    private func sendExposureIfNeeded() {
        let value = internalValue
        
        if lastExposedValue != value {
            setLastExposedValue(newValue: value)
            exposure()
        }
    }
    
    func updatePayload(_ newValue: [String: Any]?) {
        setManualReassignPayload(with: newValue)
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
    private func exposure() {
        guard let configManager = CoreManager.internalShared.remoteConfigManager else {
            return
        }
        
        configManager.exposure(forConfig: self)
    }
}

extension ExtendedRemoteConfigurable {
    internal var internalValue: String {
        get {
            if let _ = ProcessInfo.processInfo.environment["xctest_skip_config"] {
                if let _ = ProcessInfo.processInfo.environment["xctest_remote_config_enabled"] {
                    return manualReassignedValue ?? stickyBuckettedValue ?? remoteValue
                }
                return manualReassignedValue ?? defaultValue
            }
            
            return manualReassignedValue ?? stickyBuckettedValue ?? remoteValue
        }
    }
    
    internal var internalPayload: [String: Any]? {
        get {
            if let _ = ProcessInfo.processInfo.environment["xctest_skip_config"] {
                return manualReassignedPayload
            }
            
            return manualReassignedPayload ?? remotePayload
        }
    }
}

extension ExtendedRemoteConfigurable {
    private var remoteValue: String {
        guard let configManager = CoreManager.internalShared.remoteConfigManager else {
            return defaultValue
        }
        
        return configManager.getValue(forConfig: self) ?? defaultValue
    }
    
    internal var remotePayload: [String: Any]? {
        guard let configManager = CoreManager.internalShared.remoteConfigManager else {
            return nil
        }
        
        return configManager.getPayload(forConfig: self)
    }
}

extension ExtendedRemoteConfigurable {
    private var manualReassignedValue: String? {
        let savedValue = UserDefaults.standard.object(forKey: "internal"+key) as? String
        return savedValue
    }
    
    private func setManualReassignValue(with newValue: String?) {
        UserDefaults.standard.setValue(newValue, forKey: "internal"+key)
    }
    
    private var manualReassignedPayload: [String: Any]? {
        let savedPayload = UserDefaults.standard.object(forKey: "coreintegrations_" + key + "_payload") as? [String: Any]
        return savedPayload
    }
    
    private func setManualReassignPayload(with newPayload: [String: Any]?) {
        UserDefaults.standard.setValue(newPayload, forKey: "coreintegrations_" + key + "_payload")
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

