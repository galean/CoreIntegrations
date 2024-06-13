//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 19.07.2023.
//

import UIKit
import Amplitude

public class AnalyticsManager {
    var printDebugAnalytics: Bool {
        return true
    }
    
    // MARK: - Properties
    public static var shared = AnalyticsManager()
    
    // MARK: - MethodsforceEventsUpload
    
    public func configure(appKey: String, cnConfig: Bool, customURL: String) {
        Amplitude.instance().initializeApiKey(appKey)
        Amplitude.instance().defaultTracking.sessions = true
        Amplitude.instance().minTimeBetweenSessionsMillis = 0
//        Amplitude.instance().useDynamicConfig = useDynamicConfig
        if cnConfig {
            Amplitude.instance().setServerUrl(customURL)
        }
    }
    
    public func forceEventsUpload() {
        Amplitude.instance().uploadEvents()
    }
    
    public func setUserID(_ userID: String) {
        guard userID != Amplitude.instance().userId else {
            return
        }
        Amplitude.instance().setUserId(userID, startNewSession: false)
    }
    
    internal func sendCohort() {
        let userDef = UserDefaults.standard
        guard !userDef.bool(forKey: "isCohortSended") else {
            print("COHORT SENDED")
            return
        }
        print("COHORT NOT SENDED")
        #if DEBUG
        return
        #endif
        userDef.set(true, forKey: "isCohortSended")
        
        let date:Date = Date()
        
        let calendar = Calendar.current
        let monthOfYear = calendar.component(.month, from: date) as Any
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date)! as Any
        let weekOfYear = calendar.ordinality(of: .weekOfYear, in: .year, for: date)! as Any
        
        let identify = AMPIdentify()
        identify.setOnce("cohort_date", value: dayOfYear as? NSObject)
        identify.setOnce("cohort_week", value: weekOfYear as? NSObject)
        identify.setOnce("cohort_month", value: monthOfYear as? NSObject)
        
        Amplitude.instance().identify(identify)
    }
    
    func saveAttributionDetails(_ attributionDetails: [String : NSObject]?) {
        guard let details = attributionDetails else {
            return
        }
        
        let identify = AMPIdentify()
        details.keys.forEach { key in
            identify.set(key, value: details[key] as NSObject?)
        }
        Amplitude.instance().identify(identify)
    }
    
    func amplitudeLog(event: String, with properties: [AnyHashable: Any] = [String: Any]()) {
        if properties.isEmpty {
            Amplitude.instance().logEvent(event)
        } else {
            Amplitude.instance().logEvent(event, withEventProperties: properties)
        }
        
        if printDebugAnalytics {
            if properties.isEmpty {
                print("Analytics logged \(event.uppercased())")
            } else {
                print("Analytics logged \(event.uppercased()), values \(properties)")
            }
        }
    }
    
    func amplitudeIdentify(key: String, value: NSObject) {
        let identify = AMPIdentify.init().set(key, value: value)
        if let identity = identify {
            Amplitude.instance().identify(identity)
        } else {
            assertionFailure()
        }
        
        if printDebugAnalytics {
            print("Analytics identified user \(key.uppercased()) to \(value)")
        }
    }
    
    func amplitudeIncrement(key: String, value: NSObject) {
        let identify = AMPIdentify.init().add(key, value: value)
        if let identity = identify {
            Amplitude.instance().identify(identity)
        } else {
            assertionFailure()
        }
        
        if printDebugAnalytics {
            print("Analytics identified user \(key.uppercased()) to \(value)")
        }
    }
    
    func setUserProperties(_ userProperties: [String: Any]) {
        let dictionary = userProperties.reduce(into: [NSString:Any]()) {
            partialResult, result in
            partialResult[NSString(string: result.key)] = result.value
        }
        Amplitude.instance().setUserProperties(dictionary)
    }
}
