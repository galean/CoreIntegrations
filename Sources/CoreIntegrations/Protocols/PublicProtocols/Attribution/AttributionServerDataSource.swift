//
//  AttributionServerDataSource.swift
//  
//
//  Created by Anzhy on 16.10.2023.
//

import Foundation

public protocol AttributionServerDataSource {
    associatedtype AttributionEndpoints: AttributionServerEndpointsProtocol
}

extension AttributionServerDataSource {
    var serverURLPath: String {
        return AttributionEndpoints.serverURLPath
    }
    
    var installPath: String {
        return AttributionEndpoints.install.rawValue
    }
    
    var purchasePath: String {
        return AttributionEndpoints.purchase.rawValue
    }
}
