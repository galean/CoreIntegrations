
import UIKit
import AmplitudeSwift
import AmplitudeSwiftSessionReplayPlugin
import LoggingIntegration

public class AnalyticsManager {
    var printDebugAnalytics: Bool {
        return true
    }
    
    // MARK: - Properties
    public static var shared = AnalyticsManager()
    
    private var amplitude: Amplitude?
    
    private var sessionReplayPlugin:AmplitudeSwiftSessionReplayPlugin? = nil
    
    // MARK: - MethodsforceEventsUpload
    
    public func configure(data: AmplitudeConfigData) {
        sessionReplayPlugin = AmplitudeSwiftSessionReplayPlugin(sampleRate: data.sessionReplayConfig.sampleRate, enableRemoteConfig: data.sessionReplayConfig.enableRemoteConfig)
        
        amplitude = Amplitude(configuration: Configuration(apiKey: data.appKey, autocapture: .all))
        amplitude?.configuration.minTimeBetweenSessionsMillis = 3000
        data.plugins.forEach { amplitude?.add(plugin: $0) }
        
        if data.sessionReplayConfig.startOnLaunch {
            startSessionReplayRecord()
        }
        
        if let customURL = data.customURL, data.cnConfig == true {
            amplitude?.configuration.serverUrl = customURL
        }
    }
    
    
    public func startSessionReplayRecord() {
        if let sessionReplayPlugin = sessionReplayPlugin {
            amplitude?.add(plugin: sessionReplayPlugin)
        } else {
            assertionFailure()
        }
    }
    
    public func stopSessionReplayRecord() {
        if let sessionReplayPlugin = sessionReplayPlugin {
            amplitude?.remove(plugin: sessionReplayPlugin)
        } else {
            assertionFailure()
        }
    }
    
    public func forceEventsUpload() {
        amplitude?.flush()
    }
    
    public func setUserID(_ userID: String) {
        guard userID != amplitude?.getUserId() else {
            return
        }
        
        amplitude?.setUserId(userId: userID)
    }
    
    public func clearUserID() {
        amplitude?.reset()
    }
    
    func saveAttributionDetails(_ attributionDetails: [String : NSObject]?) {
        guard let details = attributionDetails else {
            return
        }
        
        let identify = Identify()
        details.keys.forEach { key in
            identify.set(property: key, value: details[key])
        }
        amplitude?.identify(identify: identify)
    }
    
    func amplitudeLog(event: String, with properties: [String: Any] = [String: Any]()) {
        guard let amplitude else {
            logDropped("event \(event.uppercased())")
            return
        }
        
        if properties.isEmpty {
            amplitude.track(eventType: event)
        } else {
            amplitude.track(
                eventType: event,
                eventProperties: properties
            )
        }
        
        if printDebugAnalytics {
            if properties.isEmpty {
                DebugLogger.log("Amplitude logged \(event.uppercased())")
            } else {
                DebugLogger.log("Amplitude logged \(event.uppercased()), properties \(properties)")
            }
        }
        
        amplitude.flush()
    }
    
    func amplitudeIdentify(key: String, value: NSObject) {
        guard let amplitude else {
            logDropped("user property \(key.uppercased())")
            return
        }
        
        let identify = Identify().set(property: key, value: value)
        amplitude.identify(identify: identify)
        
        if printDebugAnalytics {
            DebugLogger.log("Amplitude identified property: \(key.uppercased()), value: \(value)")
        }
    }
    
    func amplitudeIncrement(key: String, value: NSObject) {
        guard let amplitude else {
            logDropped("increment of user property \(key.uppercased())")
            return
        }
        
        let identify = Identify().add(property: key, value: value as? Int ?? 0)
        amplitude.identify(identify: identify)
        
        if printDebugAnalytics {
            DebugLogger.log("Analytics incremented property: \(key.uppercased()), value: \(value)")
        }
    }
    
    func amplitudeUnset(key: String) {
        guard let amplitude else {
            logDropped("unset of user property \(key.uppercased())")
            return
        }
        
        let identify = Identify().unset(property: key)
        amplitude.identify(identify: identify)
        
        if printDebugAnalytics {
            DebugLogger.log("Amplitude unset property: \(key.uppercased())")
        }
    }
    
    func setUserProperties(_ userProperties: [String: Any]) {
        guard let amplitude else {
            logDropped("user properties \(userProperties.keys.sorted())")
            return
        }
        
        amplitude.identify(userProperties: userProperties)
    }
    
    private func logDropped(_ what: String) {
        if printDebugAnalytics {
            DebugLogger.log("Amplitude is not configured yet, dropped \(what)")
        }
    }
}
