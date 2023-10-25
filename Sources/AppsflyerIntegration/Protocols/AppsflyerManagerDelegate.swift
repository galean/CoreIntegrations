//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 18.09.2023.
//

import Foundation

public protocol AppsflyerManagerDelegate {
    func handledDeeplink(_ result: [String: String])
}
