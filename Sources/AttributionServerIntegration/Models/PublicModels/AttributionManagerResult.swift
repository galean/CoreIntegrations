//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation

public struct AttributionManagerResult: Codable {
    public let userUUID: AttributionUserUUID
    public let idfv: String?
    public let asaAttribution: [String: String]
    public let isIPAT: Bool
}

//public typealias AttributionManagerResult = ((_ userUUID: AttributionUserUUID?, _ ASAAttribution: [String : NSObject]?, _ isIPAT: Bool?) -> Void)
