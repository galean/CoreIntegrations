//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 13.10.2023.
//

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
