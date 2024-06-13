//
//  CoreManagerDelegate.swift
//  
//
//  Created by Andrii Plotnikov on 03.10.2023.
//

import Foundation

public protocol CoreManagerDelegate: AnyObject {
    func coreConfigurationFinished(result: CoreManagerResult)
    func coreConfigurationUpdated(newResult: CoreManagerResult)
    
    func coreConfiguration(didReceive deepLinkResult: [AnyHashable : Any])
    func coreConfiguration(handleDeeplinkError error: Error)
}

public extension CoreManagerDelegate {
    func coreConfiguration(didReceive deepLinkResult: [AnyHashable : Any]) {
        
    }
}
