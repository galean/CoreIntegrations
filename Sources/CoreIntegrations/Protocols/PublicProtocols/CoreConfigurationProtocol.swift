//
//  CoreConfigurationProtocol.swift
//  
//
//  Created by Andrii Plotnikov on 03.10.2023.
//

import Foundation
import AppsflyerIntegration

public protocol CoreConfigurationProtocol {//}: CoreIntegrationDelegate {
    var appSettings: CoreSettingsProtocol { get }
    var remoteConfigDataSource: any CoreRemoteDataSource { get }
    var amplitudeDataSource: any CoreAnalyticsDataSource { get }
    var initialConfigurationDataSource: (any ConfigurationEventsDataSource)? { get }
    var attributionServerDataSource: any AttributionServerDataSource { get }
    var paywallDataSource: any CorePaywallDataSource { get }
    var useDefaultATTRequest: Bool { get }
}

extension CoreConfigurationProtocol {
    var useDefaultATTRequest: Bool { return true }
    
    var appsflyerConfig: AppsflyerConfigData {
        return AppsflyerConfigData(appsFlyerDevKey: appSettings.appsFlyerKey,
                                   appleAppID: appSettings.appID)
    }
}

