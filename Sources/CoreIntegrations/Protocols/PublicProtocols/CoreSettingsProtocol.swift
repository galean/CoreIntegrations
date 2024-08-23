//
//  CoreSettingsProtocol.swift
//  
//
//  Created by Andrii Plotnikov on 03.10.2023.
//

import Foundation

public protocol CoreSettingsProtocol: AnyObject {
    var appID: String { get }
    var appsFlyerKey: String { get }
    var attributionServerSecret: String { get }
    var subscriptionsSecret: String { get }
    
    var amplitudeSecret: String { get }
    var amplitudeDeploymentKey: String? { get }
    
    var launchCount: Int { get set }
    
    var paywallSourceForRestricted: CoreUserSource? { get }
}

public extension CoreSettingsProtocol {
    var isFirstLaunch: Bool {
        launchCount == 1
    }
    
    var paywallSourceForRestricted: CoreUserSource? {
        return nil
    }
    
    var amplitudeDeploymentKey: String? {
        return nil
    }
}
