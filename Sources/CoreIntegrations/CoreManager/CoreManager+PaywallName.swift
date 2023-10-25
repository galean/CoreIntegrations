//
//  CoreManager+PaywallName.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
import FirebaseIntegration
import AppsflyerIntegration

//typealias PaywallName = String
//enum PaywallDefaultType {
//    case organic
//    case web2app
//    case fb_google_redirect
//    
//    var defaultPaywallName: PaywallName {
//        return "default"
//    }
//}

//extension CoreManager {
//    func getActivePaywallName(generalPaywalConfig: any CoreRemoteABTestable,
//                              fbGooglePaywalConfig: any CoreRemoteABTestable,
//                              deepLinkResult: [String: String]) -> String {
//        let paywallName: String
//        if deepLinkResult.isEmpty == false {
//            paywallName = getGeneralPaywallName(generalPaywalConfig: generalPaywalConfig)
//        } else {
//            paywallName = getFbGooglePaywallName(fbGooglePaywalConfig: fbGooglePaywalConfig)
//        }
//
//        return paywallName
//    }
//
//    func getGeneralPaywallName(generalPaywalConfig: any CoreRemoteABTestable) -> String {
//        return getPaywallNameFromConfig(generalPaywalConfig)
//
//    }
//
//    func getFbGooglePaywallName(fbGooglePaywalConfig: any CoreRemoteABTestable) -> String {
//        return getPaywallNameFromConfig(fbGooglePaywalConfig)
//    }
//
//    private func getPaywallNameFromConfig(_ config: any CoreRemoteABTestable) -> String {
//        let paywallName: String
//        let value = config.value
//        if value.hasPrefix("none_") {
//            paywallName = String(value.dropFirst("none_".count))
//        } else {
//            paywallName = value
//        }
//        return paywallName
//    }
//}
