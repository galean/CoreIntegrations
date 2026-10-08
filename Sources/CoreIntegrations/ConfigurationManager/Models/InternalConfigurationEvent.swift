
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

    /// Main thread only: for results delivered on main that are not tied to an attempt, e.g. ATT, AppsFlyer delegate.
    func markAsCompleted(error: Error? = nil) {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        configurationManager.handleCompleted(event: self, error: error)
    }

    /// Any thread: for completions of requests started on main in `generation`; dropped once it is reset.
    func markAsCompleted(error: Error? = nil, generation: Int) {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        configurationManager.handleCompleted(event: self, error: error, generation: generation)
    }
}
