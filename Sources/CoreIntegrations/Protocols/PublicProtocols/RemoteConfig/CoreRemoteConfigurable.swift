//
//  CoreRemoteConfigurable.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
import Experiment

public protocol CoreRemoteConfigurable: CaseIterable, CoreFirebaseConfigurable {
    static var subscription_screen_style_full: Self { get }
    static var subscription_screen_style_h: Self { get }
    static var rate_us_primary_shown: Self { get }
    static var rate_us_secondary_shown: Self { get }
    
    var amplitudeValue: String { get }
    
    func getAmplitudeValueWithFetching(completion: @escaping (String) -> Void)
    
    static var allAmplitudeValues: [String: String] { get }
}

public extension CoreRemoteConfigurable {
    var value: String {
        get {
            let savedValue = UserDefaults.standard.object(forKey: key) as? String
            return savedValue ?? defaultValue
        }
    }
    
    func updateValue(_ newValue: String) {
        UserDefaults.standard.setValue(newValue, forKey: key)
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
    
    var amplitudeValue: String {
        get {
            return CoreManager.internalShared.remoteConfigManager?.getValue(key: self.key) ?? ""
        }
    }
    
    func getAmplitudeValueWithFetching(completion: @escaping (String) -> Void) {
        CoreManager.internalShared.remoteConfigManager?.getValueWithFetching(key: self.key, completion: completion)
    }
    
    static var allAmplitudeValues: [String: String] {
        get {
            let variants = CoreManager.internalShared.remoteConfigManager?.amplitudeVariants ?? [String: Variant]()
            return variants.reduce(into: [String: String]()) { partialResult, valueWithKey in
                partialResult[valueWithKey.key] = valueWithKey.value.value
            }
        }
    }
}
