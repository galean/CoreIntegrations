//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation

internal protocol AttributionDataWorkerProtocol {
    var idfa: String? { get }
    var idfv: String? { get }
    var uuid: String { get }
    var sdkVersion: String { get }
    var osVersion: String { get }
    var appVersion: String { get }
    var isAdTrackingEnabled: Bool { get }
    var attributionDetails: [String: String]? { get }
    var storeCountry: String { get }
    
    var receiptToken: String { get }
    
    func generateUniqueToken() -> String
}
