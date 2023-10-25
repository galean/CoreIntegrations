//
//  CoreRemoteConfigurable.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation

public protocol CoreRemoteConfigurable: CaseIterable, CoreFirebaseConfigurable {
    static var subscription_screen_style_full: Self { get }
    static var subscription_screen_style_h: Self { get }
    static var rate_us_primary_shown: Self { get }
    static var rate_us_secondary_shown: Self { get }
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
}
