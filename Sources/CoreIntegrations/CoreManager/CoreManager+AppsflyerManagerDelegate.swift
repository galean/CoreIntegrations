//
//  CoreManager+AppsflyerManagerDelegate.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
#if !COCOAPODS
import AppsflyerIntegration
#endif

extension CoreManager: AppsflyerManagerDelegate {
    public func handledDeeplink(_ result: [String : String]) {
        sendDeepLinkUserProperties(deepLinkResult: result)
        InternalConfigurationEvent.appsflyerWeb2AppHandled.markAsCompleted()
        
        handleConfigurationUpdate()
    }
}
