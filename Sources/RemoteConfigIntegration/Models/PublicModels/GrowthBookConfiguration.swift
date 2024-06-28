//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 28.06.2024.
//

import Foundation

public struct GrowthBookConfiguration {
    var clientKey: String
    var hostURL: String
    
    public init(clientKey: String, hostURL: String) {
        self.clientKey = clientKey
        self.hostURL = hostURL
    }
}
