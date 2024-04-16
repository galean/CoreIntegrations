//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 18.09.2023.
//

import Foundation

public protocol AppsflyerManagerDelegate {
    func handledDeeplink(_ result: [String: String])
    
    func coreConfiguration(didResolveDeeplink result: [AnyHashable : Any])
    func coreConfiguration(didReceive deepLinkResult: [AnyHashable : Any])
    func coreConfiguration(handleDeeplinkError error: Error)
    func coreConfiguration(handleOnAppOpenAttribution deepLinkResult: [AnyHashable : Any])
    func coreConfiguration(handleOnAppOpenAttributionError error: Error)

}
