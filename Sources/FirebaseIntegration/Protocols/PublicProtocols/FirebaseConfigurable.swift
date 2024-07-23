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

protocol RemoteConfigManager {
    var remoteConfigResult: [String: String]? { get }
    var internalConfigResult: [String: String]?  { get }
    var install_server_path: String?  { get }
    var purchase_server_path: String? { get }
    
    var kInstallURL: String { get }// = "install_server_path"
    var kPurchaseURL: String { get }// = "purchase_server_path"
    
    func configure(id: String, completion: @escaping () -> Void)
    func fetchRemoteConfig(_ appConfigurables: [any FirebaseConfigurable], completion: @escaping () -> Void)
}

extension RemoteConfigManager {
    var kInstallURL: String {
        return "install_server_path"
    }
    
    var kPurchaseURL: String {
        return "purchase_server_path"
    }
}
