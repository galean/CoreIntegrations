//
//  InternalAnalyticsEvent.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
import AnalyticsIntegration

enum InternalAnalyticsEvent: String, CaseIterable, AmplitudeAnalyzableEvent {
    case first_launch
    case test_distribution
    case att_permission
    
    public var key: String {
        return rawValue
    }
}
