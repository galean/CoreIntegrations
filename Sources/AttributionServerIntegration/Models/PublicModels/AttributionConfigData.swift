//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation

public struct AttributionConfigData {
    let authToken: AttributionServerToken
    let serverURLPath: String
    let installPath: String
    let purchasePath: String
    let appsflyerID: String?
    let facebookData: AttributionFacebookModel?
    
    public init(authToken: AttributionServerToken, serverURLPath: String, installPath: String, purchasePath: String,
                appsflyerID: String?, facebookData: AttributionFacebookModel?) {
        self.authToken = authToken
        self.appsflyerID = appsflyerID
        self.facebookData = facebookData
        self.serverURLPath = serverURLPath
        self.installPath = installPath
        self.purchasePath = purchasePath
    }
}
