
import Foundation

public protocol RemoteConfigurable {
    var key: String { get }
    var defaultValue: String { get }
    var value: String { get }
    
//    func updateValue(_ newValue: String)
}
