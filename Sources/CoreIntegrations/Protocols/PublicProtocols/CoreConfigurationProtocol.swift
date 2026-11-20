
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
    var isFacebookEnabled: Bool { get }
    var isAdPartnersDataSharingEnabled: Bool { get }
    /// The user's ad consent at launch. A value marks the user as subject to GDPR; return `nil` for everyone else.
    var adConsent: AdConsent? { get }
    var hasExternalAuthorization: Bool { get }
    var hasCustomFirebaseConfiguration: Bool { get }
    var configurationTimeout: Int { get }
    var attributionServerDataSource: any AttributionServerDataSource { get }
    var sentryConfigDataSource: (any SentryDataSourceProtocol)? { get }
    var appLocalization: String { get }
    var customAmplitudeServer: String? { get }
    var isDebugLoggingEnabled: Bool { get }
}

public extension CoreConfigurationProtocol {
    var isFacebookEnabled: Bool { return true }
    
    var isAdPartnersDataSharingEnabled: Bool { return true }
    
    var adConsent: AdConsent? { return nil }
    
    var useDefaultATTRequest: Bool { return true }
    
    var configurationTimeout: Int {
        return 6
    }
    
    var appsflyerConfig: AppsflyerConfigData {
        return AppsflyerConfigData(appsFlyerDevKey: appSettings.appsFlyerKey,
                                   appleAppID: appSettings.appID)
    }
    
    var appLocalization: String {
        return Locale.current.identifier
    }
    
    var customAmplitudeServer: String? {
        return nil
    }
    
    var isDebugLoggingEnabled: Bool { return false }
}
