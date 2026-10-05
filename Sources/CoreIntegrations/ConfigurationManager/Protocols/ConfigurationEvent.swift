
import Foundation

public protocol ConfigurationEvent: CaseIterable {
    var key: String { get }
    func markAsCompleted()
    var isFirstStartOnly: Bool { get }
    var isRequiredToContunue: Bool { get }
}

public extension ConfigurationEvent {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.key == rhs.key
    }
    
    /// Any thread. The completion is credited to the configuration that is current when it lands on main.
    /// Mark an app-defined event once per process: it is kept when a configuration retry resets the rest.
    func markAsCompleted() {
        MainQueueExecutor.perform {
            guard let configurationManager = AppConfigurationManager.shared else {
                assertionFailure()
                return
            }
            configurationManager.handleCompleted(event: self, error: nil)
        }
    }
}
