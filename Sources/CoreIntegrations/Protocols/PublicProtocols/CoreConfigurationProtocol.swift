
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
    /// Whether the user's data may be shared with advertising partners.
    /// Mirrors the CCPA/CPRA "Do Not Sell or Share My Personal Information" choice: `false` means the user opted out.
    /// Read once while the framework configures; use `CoreManagerProtocol.setAdPartnersDataSharingEnabled(_:)` for later changes.
    var isAdPartnersDataSharingEnabled: Bool { get }
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
