//
//  CoreAnalyzableEvent.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
#if !COCOAPODS
import AnalyticsIntegration
#endif

public protocol CoreAnalyzableEvent: CaseIterable, AmplitudeAnalyzableEvent {
    static var contact_permission: Self { get }
    static var notification_permission: Self { get }
    static var location_permission: Self { get }
    static var gallery_permission: Self { get }
    static var camera_permission: Self { get }
    static var microphone_permission: Self { get }
    static var local_network_permission: Self { get }

    static var subscription_shown: Self { get }
    static var subscription_subscribe_clicked: Self { get }
    static var subscription_purchased: Self { get }
    static var subscription_closed: Self { get }
    static var subscription_restore_clicked: Self { get }
    static var subscription_error: Self { get }

    static var push_notification_opened: Self { get }
    static var custom_rate_us_shown: Self { get }
}
