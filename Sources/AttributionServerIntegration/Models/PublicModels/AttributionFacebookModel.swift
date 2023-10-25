//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation

public struct AttributionFacebookModel {
    var fbUserId: String
    var fbUserData: String
    var fbAnonId: String
    
    public init(fbUserId: String, fbUserData: String, fbAnonId: String) {
        self.fbUserId = fbUserId
        self.fbUserData = fbUserData
        self.fbAnonId = fbAnonId
    }
}
