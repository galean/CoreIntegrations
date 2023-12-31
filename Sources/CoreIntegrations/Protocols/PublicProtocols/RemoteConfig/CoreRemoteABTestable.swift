//
//  CoreRemoteABTestable.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation

public protocol CoreRemoteABTestable: CaseIterable, CoreFirebaseConfigurable {
    static var ab_paywall_general: Self { get }
    static var ab_paywall_fb_google: Self { get }
}

public extension CoreRemoteABTestable {
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
