
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
    
    func markAsCompleted() {
        guard let configurationManager = AppConfigurationManager.shared else {
            assertionFailure()
            return
        }
        configurationManager.handleCompleted(event: self)
    }
}
