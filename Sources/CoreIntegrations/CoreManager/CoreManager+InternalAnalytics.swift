
import Foundation
#if !COCOAPODS
import AnalyticsIntegration
import AppsflyerIntegration
#endif
import StoreKit

enum AppConfiguration: String {
  case Debug
  case Testing
  case AppStore
}

struct Config {
    // This is private because the use of 'appConfiguration' is preferred.
    private static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" || Bundle.main.appStoreReceiptURL == nil
    
    // This can be used to add debug statements.
    static var isDebug: Bool {
    #if DEBUG
        return true
    #else
        return false
    #endif
    }
    
    static var appConfiguration: AppConfiguration {
        if isDebug {
            return .Debug
        } else if isTestFlight {
            return .Testing
        } else {
            return .AppStore
        }
    }
}

extension CoreManager {
    func sendAppEnvironmentProperty() {
        InternalUserProperty.app_environment.identify(parameter: AppEnvironment.current.rawValue)
    }
    
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
    
    //    func sendDeepLinkUserProperties(deepLinkResult: [String: String]) {
    //        let userProperties = deepLinkResult
    //        InternalUserProperty.identify(userProperties)
    //    }
    
#warning("Should be removed after tests")
    func sendOnBecomeActive(status: [String: String]) {
        let internetStatus = ["connection": "\(NetworkManager.shared.isConnected)", "connection_type": NetworkManager.shared.currentConnectionType?.description ?? "unexpected"]
        InternalAnalyticsEvent.framework_entered_foreground.log(parameters: status+internetStatus)
        analyticsManager?.forceEventsUpload()
    }
    
    func sendConfigurationDelaied(status: [String: String]) {
        let internetStatus = ["connection": "\(NetworkManager.shared.isConnected)", "connection_type": NetworkManager.shared.currentConnectionType?.description ?? "unexpected"]
        InternalAnalyticsEvent.framework_start_delaied.log(parameters: status+internetStatus)
        analyticsManager?.forceEventsUpload()
    }
    
    func sendConfigurationStarted(status: [String: String]) {
        let internetStatus = ["connection": "\(NetworkManager.shared.isConnected)", "connection_type": NetworkManager.shared.currentConnectionType?.description ?? "unexpected"]
        InternalAnalyticsEvent.framework_attribution_started.log(parameters: status+internetStatus)
        analyticsManager?.forceEventsUpload()
    }
    
    func sendUserAttribution(userAttribution: [String: String], status: [String: String]) {
        let internetStatus = ["connection": "\(NetworkManager.shared.isConnected)", "connection_type": NetworkManager.shared.currentConnectionType?.description ?? "unexpected"]
        
        guard userAttribution.isEmpty == false else {
            InternalAnalyticsEvent.framework_attribution.log(parameters: status+internetStatus)
            analyticsManager?.forceEventsUpload()
            return
        }
        
        InternalUserProperty.identify(userAttribution)
        InternalAnalyticsEvent.framework_attribution.log(parameters: userAttribution+status+internetStatus)
        analyticsManager?.forceEventsUpload()
    }
    
    func sendUserAttributionUpdate(userAttribution: [String: String]) {
        let internetStatus = ["connection": "\(NetworkManager.shared.isConnected)", "connection_type": NetworkManager.shared.currentConnectionType?.description ?? "unexpected"]
        
        guard userAttribution.isEmpty == false else { return }
        
        InternalUserProperty.identify(userAttribution)
        InternalAnalyticsEvent.framework_attribution_update.log(parameters: userAttribution+internetStatus)
        analyticsManager?.forceEventsUpload()
    }
    
    func sendConfigurationFinished(status: [String: String]) {
        let internetStatus = ["connection": "\(NetworkManager.shared.isConnected)", "connection_type": NetworkManager.shared.currentConnectionType?.description ?? "unexpected"]
        
        InternalAnalyticsEvent.framework_finished.log(parameters: status+internetStatus)
        analyticsManager?.forceEventsUpload()
    }
    
    
    
//    func sendABTestsUserProperties(abTests: [any CoreRemoteConfigurable], userSource: CoreUserSource) { // +
//        let userProperties = abTests.reduce(into: [String:String]()) { partialResult, abtest in
//            partialResult[abtest.key] = abtest.value
//        }
//        InternalUserProperty.identify(userProperties)
//    }
//    
//    func sendTestDistributionEvent(abTests: [any CoreRemoteConfigurable], deepLinkResult: [String: String],
//                                   userSource: CoreUserSource) { // +
//        var parameters = abTests.reduce(into: [String:String]()) { partialResult, abtest in
//            partialResult[abtest.key] = abtest.value
//        }
//        
//        parameters = parameters + deepLinkResult
//        
//        InternalAnalyticsEvent.test_distribution.log(parameters: parameters)
//        analyticsManager?.forceEventsUpload()
//    }
    
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
