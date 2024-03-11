//
//  CoreManager+InternalAnalytics.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
import FirebaseIntegration
import AnalyticsIntegration
import AppsflyerIntegration
import StoreKit

extension CoreManager {
    func sendFirstLaunchEvent() {
        InternalAnalyticsEvent.first_launch.log()
        analyticsManager?.forceEventsUpload()
    }
    
    func sendAttEvent(answer: Bool) {
        sendATTProperty(answer: answer)
        InternalAnalyticsEvent.att_permission.log(parameter: answer)
        analyticsManager?.forceEventsUpload()
    }
    
    func sendATTProperty(answer: Bool) {
        InternalUserProperty.att_status.identify(parameter: "\(answer)")
    }
    
    func sendDeepLinkUserProperties(deepLinkResult: [String: String]) {
        let userProperties = deepLinkResult
        InternalUserProperty.identify(userProperties)
    }
    
    func sendABTestsUserProperties(abTests: [any CoreRemoteABTestable], userSource: CoreUserSource) { // +
        let userProperties = abTests.reduce(into: [String:String]()) { partialResult, abtest in
            let shouldSend: Bool = abtest.activeForSources.contains(userSource)
            var value = abtest.value
            if !shouldSend {
                value = "none"
            } else if value.contains("none_") {
                value = "none"
            }
            partialResult[abtest.key] = value
        }
        InternalUserProperty.identify(userProperties)
    }
    
    func sendTestDistributionEvent(abTests: [any CoreRemoteABTestable], deepLinkResult: [String: String],
                                   userSource: CoreUserSource) { // +
        var parameters = abTests.reduce(into: [String:String]()) { partialResult, abtest in
            let shouldSend: Bool = abtest.activeForSources.contains(userSource)
            var value = abtest.value
            if !shouldSend {
                value = "none"
            } else if value.contains("none_") {
                value = "none"
            }
            partialResult[abtest.key] = value
        }
        
        parameters = parameters + deepLinkResult
        
        InternalAnalyticsEvent.test_distribution.log(parameters: parameters)
        analyticsManager?.forceEventsUpload()
    }
    
    func sendStoreCountryUserProperty() {
        Task {
            let country = await Storefront.current?.countryCode ?? ""
            InternalUserProperty.store_country.identify(parameter: country)
        }
    }
    
    func sendSubscriptionTypeUserProperty(identifier: String) {
        InternalUserProperty.subscription_type.identify(parameter: identifier)
    }
}

extension Dictionary {
    static func += (lhs: inout [Key:Value], rhs: [Key:Value]) {
        lhs.merge(rhs){$1}
    }
    static func + (lhs: [Key:Value], rhs: [Key:Value]) -> [Key:Value] {
        return lhs.merging(rhs){$1}
    }
}
