
import Foundation

#if !COCOAPODS
import AppsflyerIntegration
#endif

public protocol CoreConfigurationProtocol {
    var appSettings: CoreSettingsProtocol { get }
    var remoteConfigDataSource: any CoreRemoteDataSource { get }
    var amplitudeDataSource: any CoreAnalyticsDataSource { get }
    var initialConfigurationDataSource: (any ConfigurationEventsDataSource)? { get }
    var paywallDataSource: any CorePaywallDataSource { get }
    var useDefaultATTRequest: Bool { get }
    var attributionServerDataSource: any AttributionServerDataSource { get }
    var mockConfiguration: (any MockConfigurationProtocol)? { get }
    var sentryConfigDataSource: (any SentryDataSourceProtocol)? { get }
}

extension CoreConfigurationProtocol {
    var useDefaultATTRequest: Bool { return true }
    
    var appsflyerConfig: AppsflyerConfigData {
        return AppsflyerConfigData(appsFlyerDevKey: appSettings.appsFlyerKey,
                                   appleAppID: appSettings.appID)
    }
}

public protocol MockConfigurationProtocol {
    var appsflyerDeepLink: [AnyHashable: Any]? { get }
    var isPremium: Bool { get }
    var userData: [AnyHashable: Any]? { get }
    var network: CoreUserSource? { get }
    var paywallName: String? { get }
    var useDefaultATTRequest: Bool? { get }
}
