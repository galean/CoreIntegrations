//
//  CoreManagerDelegate.swift
//  
//
//  Created by Andrii Plotnikov on 03.10.2023.
//

import Foundation

public protocol CoreManagerDelegate: AnyObject {
    func coreConfigurationFinished(result: CoreManagerResult)
    func appUpdateRequired(result: ForceUpdateResult)
}
