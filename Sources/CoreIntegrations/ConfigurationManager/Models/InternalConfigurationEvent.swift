//
//  InternalConfigurationEvent.swift
//  
//
//  Created by Andrii Plotnikov on 13.10.2023.
//

import Foundation

enum InternalConfigurationEvent: String, ConfigurationEvent {
    case attConcentGiven = "attConcentGiven"
    case remoteConfigLoaded = "remoteConfigLoaded"
    case appsflyerWeb2AppHandled = "appsflyerWeb2AppHandled"
    case revenueCatConfigured = "revenueCatConfigured"
    case attributionServerHandled = "attributionServerHandled"

    var isFirstStartOnly: Bool {
        switch self {
        case .remoteConfigLoaded, .revenueCatConfigured:
            return false
        case .attConcentGiven, .appsflyerWeb2AppHandled, .attributionServerHandled:
            return true
        }
    }

    var isRequiredToContunue: Bool {
        return false
    }

    var key: String {
        return rawValue
    }

    func markAsCompleted() {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        configurationManager.handleCompleted(event: self)
    }
}
