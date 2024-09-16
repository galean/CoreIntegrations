
import Foundation

#if !COCOAPODS
import FirebaseIntegration
import Experiment
#else
import AmplitudeExperiment
#endif

public protocol CoreFirebaseConfigurable: CaseIterable, FirebaseConfigurable {
    var boolValue: Bool { get }
    var activeForSources: [CoreUserSource] { get }
}

public extension CoreFirebaseConfigurable {
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
