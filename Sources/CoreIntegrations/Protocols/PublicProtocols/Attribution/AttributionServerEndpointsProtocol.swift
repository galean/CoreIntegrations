//
//  AttributionServerEndpointsProtocol.swift
//  
//
//  Created by Andrii Plotnikov on 16.10.2023.
//

import Foundation

public protocol AttributionServerEndpointsProtocol: RawRepresentable where RawValue == String {
    static var serverURLPath: String { get }
    static var install: Self { get }
    static var purchase: Self { get }
}
