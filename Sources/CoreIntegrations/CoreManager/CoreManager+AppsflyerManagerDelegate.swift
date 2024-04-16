//
//  CoreManager+AppsflyerManagerDelegate.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
import AppsflyerIntegration

extension CoreManager: AppsflyerManagerDelegate {
    public func coreConfiguration(didReceive deepLinkResult: [AnyHashable : Any]) {
        delegate?.coreConfiguration(didReceive: deepLinkResult)
    }
    
    public func coreConfiguration(handleDeeplinkError error: Error) {
        delegate?.coreConfiguration(handleDeeplinkError: error)
    }
    
    public func coreConfiguration(handleOnAppOpenAttribution deepLinkResult: [AnyHashable : Any]) {
        delegate?.coreConfiguration(handleOnAppOpenAttribution: deepLinkResult)
    }
    
    public func coreConfiguration(handleOnAppOpenAttributionError error: Error) {
        delegate?.coreConfiguration(handleOnAppOpenAttributionError: error)
    }
    
    public func handledDeeplink(_ result: [String : String]) {
        sendDeepLinkUserProperties(deepLinkResult: result)
        InternalConfigurationEvent.appsflyerWeb2AppHandled.markAsCompleted()
        
        handleConfigurationUpdate()
    }
}
