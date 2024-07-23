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
    var growthBookClientKey: String? { get }
    var subscriptionsSecret: String { get }
    
    var amplitudeSecret: String { get }
    var deploymentKey: String { get }
    
    var launchCount: Int { get set }
}

public extension CoreSettingsProtocol {
    var isFirstLaunch: Bool {
        launchCount == 1
    }
    var growthBookClientKey: String? {
        return nil
    }
}
