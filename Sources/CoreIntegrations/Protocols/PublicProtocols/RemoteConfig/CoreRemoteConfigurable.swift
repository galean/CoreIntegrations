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
}

public extension ExtendedRemoteConfigurable {
    var value: String {
        get {
            guard let configManager = CoreManager.internalShared.remoteConfigManager else {
                return defaultValue
            }
            
            return configManager.getValue(forConfig: self) ?? defaultValue
//            CoreManager.internalShared.remoteConfigManager.
//            let savedValue = UserDefaults.standard.object(forKey: key) as? String
//            return savedValue ?? defaultValue
        }
    }
    
//    func updateValue(_ newValue: String) {
//        UserDefaults.standard.setValue(newValue, forKey: key)
//    }
    
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
