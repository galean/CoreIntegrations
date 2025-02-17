
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
    var configurationTimeout: Int { get }
    var attributionServerDataSource: any AttributionServerDataSource { get }
    var sentryConfigDataSource: (any SentryDataSourceProtocol)? { get }
}

public extension CoreConfigurationProtocol {
    var useDefaultATTRequest: Bool { return true }
    
    var configurationTimeout: Int {
        return 6
    }
    
    var appsflyerConfig: AppsflyerConfigData {
        return AppsflyerConfigData(appsFlyerDevKey: appSettings.appsFlyerKey,
                                   appleAppID: appSettings.appID)
    }
}
