//
//  CoreConfigurationProtocol.swift
//  
//
//  Created by Andrii Plotnikov on 03.10.2023.
//

import Foundation
#if !COCOAPODS
import AppsflyerIntegration
#endif

public protocol CoreConfigurationProtocol {
    var appSettings: CoreSettingsProtocol { get }
    var remoteConfigDataSource: any CoreRemoteDataSource { get }
    var amplitudeDataSource: any CoreAnalyticsDataSource { get }
    var initialConfigurationDataSource: (any ConfigurationEventsDataSource)? { get }
    var useDefaultATTRequest: Bool { get }
    var paywallDataSource: any CorePaywallDataSource { get }
}

extension CoreConfigurationProtocol {
    var useDefaultATTRequest: Bool { return true }
    
    var appsflyerConfig: AppsflyerConfigData {
        return AppsflyerConfigData(appsFlyerDevKey: appSettings.appsFlyerKey,
                                   appleAppID: appSettings.appID)
    }
}

