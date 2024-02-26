//
//  AttributionServerEndpointsProtocol.swift
//  
//
//  Created by Andrii Plotnikov on 16.10.2023.
//

import Foundation

public protocol AttributionServerEndpointsProtocol: RawRepresentable where RawValue == String {
    static var install_server_path: Self { get }
    static var purchase_server_path: Self { get }
}
