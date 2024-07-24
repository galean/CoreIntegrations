//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation

public protocol FirebaseConfigurable {
    var key: String { get }
    var defaultValue: String { get }
    var value: String { get }
    
    func updateValue(_ newValue: String)
}
