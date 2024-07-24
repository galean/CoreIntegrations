//
//  CoreSettingsProtocol.swift
//  
//
//  Created by Andrii Plotnikov on 03.10.2023.
//

import Foundation

#if !COCOAPODS
import RemoteConfigIntegration
#endif

public protocol CoreSettingsProtocol: AnyObject {
    typealias GrowthBookConfig = (clientKey: String, apiHost: String)
    
    var appID: String { get }
    var appsFlyerKey: String { get }
    var attributionServerSecret: String { get }
    
    var growthBookConfig: GrowthBookConfig? { get }
    
    var subscriptionsSecret: String { get }
    
    var amplitudeSecret: String { get }
    var deploymentKey: String { get }
    
    var launchCount: Int { get set }
}

public extension CoreSettingsProtocol {
    var isFirstLaunch: Bool {
        launchCount == 1
    }
    var growthBookConfig: (clientKey: String, apiHost: String)? {
        return nil
    }
}

extension CoreSettingsProtocol {
    var growthBookConfiguration: GrowthBookConfiguration? {
        if let growthBookConfig {
            return GrowthBookConfiguration(clientKey: growthBookConfig.clientKey,
                                           hostURL: growthBookConfig.apiHost)
        } else {
            return nil
        }
    }
}
