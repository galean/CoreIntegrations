//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation

public protocol AmplitudeAnalyzableUserProperty {
    var key: String { get }
}

public extension AmplitudeAnalyzableUserProperty {
    static func identify(_ userProperties: [String: Any]) {
        AnalyticsManager.shared.setUserProperties(userProperties)
    }
    
    func identify(parameter: String) {
        AnalyticsManager.shared.amplitudeIdentify(key: key, value: NSString(string: parameter))
    }
    
    func identifyIncrement() {
        AnalyticsManager.shared.amplitudeIncrement(key: key, value: NSNumber(integerLiteral: 1))
    }
}
