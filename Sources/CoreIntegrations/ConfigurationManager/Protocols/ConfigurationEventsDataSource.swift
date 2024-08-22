
import Foundation

public protocol ConfigurationEventsDataSource {
    associatedtype AppInitialConfigEvents: ConfigurationEvent
    
    var allEvents: [AppInitialConfigEvents] { get }
}

public extension ConfigurationEventsDataSource {
    var allEvents: [AppInitialConfigEvents] {
        return AppInitialConfigEvents.allCases as! [Self.AppInitialConfigEvents]
    }
}
