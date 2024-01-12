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
    var revenuecatApiKey: String { get }
    
    var amplitudeSecret: String { get }
    
    //make internal launch count
    //add public getter only launch count
    var launchCount: Int { get set }
}

public extension CoreSettingsProtocol {
    var isFirstLaunch: Bool {
        launchCount == 1
    }
}
