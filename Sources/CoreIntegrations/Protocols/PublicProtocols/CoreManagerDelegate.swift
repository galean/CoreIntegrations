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
    func coreConfiguration(didReceive deepLinkReult: [AnyHashable : Any])
}

public extension CoreManagerDelegate {
    func coreConfiguration(didReceive deepLinkReult: [AnyHashable : Any]) {
        
    }
}
