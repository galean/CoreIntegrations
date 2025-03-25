
import Foundation

public protocol RemoteConfigurable {
    var key: String { get }
    var defaultValue: String { get }
    var value: String { get }
    var stickyBucketed: Bool { get }
}

