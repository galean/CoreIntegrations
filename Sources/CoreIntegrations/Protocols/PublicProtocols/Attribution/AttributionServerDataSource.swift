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
    var installPath: String {
        return AttributionEndpoints.install_server_path
    }
    var purchasePath: String {
        return AttributionEndpoints.purchase_server_path
    }
}
