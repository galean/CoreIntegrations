//
//  CoreAnalyticsDataSource.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation

public protocol CoreAnalyticsDataSource {
    associatedtype AnalyticsEvents: CoreAnalyzableEvent
    associatedtype AnalyticsUserProperties: CoreAnalyzableUserProperty
    var allEvents: [AnalyticsEvents] { get }
    var allUserProperties: [AnalyticsUserProperties] { get }
    var customServerURL: String? { get }
}

public extension CoreAnalyticsDataSource {
    var allEvents: [AnalyticsEvents] {
        return AnalyticsEvents.allCases as! [Self.AnalyticsEvents]
    }

    var allUserProperties: [AnalyticsUserProperties] {
        return AnalyticsUserProperties.allCases as! [Self.AnalyticsUserProperties]
    }
    
    var customServerURL: String? {
        return nil
    }
}

