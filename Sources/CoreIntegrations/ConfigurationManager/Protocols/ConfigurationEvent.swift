import Foundation

public protocol ConfigurationEvent: CaseIterable {
    var key: String { get }
    /// Any thread. Applied on main to the current configuration attempt and kept for later attempts:
    /// mark an app-defined event once per process.
    func markAsCompleted()
    var isFirstStartOnly: Bool { get }
    var isRequiredToContunue: Bool { get }
}

public extension ConfigurationEvent {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.key == rhs.key
    }
}
