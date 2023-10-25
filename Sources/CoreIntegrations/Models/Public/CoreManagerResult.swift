//
//  CoreManagerResult.swift
//  
//
//  Created by Andrii Plotnikov on 03.10.2023.
//

import Foundation

public struct CoreManagerResult {
    public var userSource: CoreUserSource
    public var activePaywallName: String
    public var organicPaywallName: String
    public var fbgoogleredictPaywallName: String
}

//public enum CoreManagerResult {
//    case success(data: CoreManagerResultData)
//    case error(defaultData: CoreManagerResultData)
//}
