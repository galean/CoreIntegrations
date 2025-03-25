
import Foundation

enum InternalConfigurationEvent: String, ConfigurationEvent {
    case attConcentGiven = "attConcentGiven"
    case remoteConfigLoaded = "remoteConfigLoaded"
    case appsflyerWeb2AppHandled = "appsflyerWeb2AppHandled"
    case attributionServerHandled = "attributionServerHandled"
    case remoteConfigUpdated = "remoteConfigUpdated"

    var isFirstStartOnly: Bool {
        switch self {
        case .remoteConfigLoaded:
            return false
        case .attConcentGiven, .appsflyerWeb2AppHandled, .attributionServerHandled, .remoteConfigUpdated:
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
