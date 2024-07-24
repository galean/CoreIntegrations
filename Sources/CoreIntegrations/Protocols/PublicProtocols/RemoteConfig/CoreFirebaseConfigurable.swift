//
//  File.swift
//  
//
//  Created by Anzhy on 20.10.2023.
//

import Foundation
#if !COCOAPODS
import RemoteConfigIntegration
#endif
import Experiment

public protocol CoreFirebaseConfigurable: CaseIterable, FirebaseConfigurable {
    var boolValue: Bool { get }
    var activeForSources: [CoreUserSource] { get }
    
    var amplitudeValue: String { get }
    
    static var allAmplitudeValues: [String: String] { get }
}

extension CoreFirebaseConfigurable {
    var amplitudeValue: String {
        get {
            let variants = CoreManager.internalShared.remoteConfigManager?.amplitudeVariants
            return variants?[self.key]?.value ?? ""
        }
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
