//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 11.08.2024.
//

import Foundation

public protocol RemoteConfigManager {
    var remoteConfigResult: [String: String]? { get }
    var internalConfigResult: [String: String]?  { get }
    var install_server_path: String?  { get }
    var purchase_server_path: String? { get }
    
    var kInstallURL: String { get }
    var kPurchaseURL: String { get }
    
    func configure(id: String, completion: @escaping () -> Void)
    func fetchRemoteConfig(_ appConfigurables: [any FirebaseConfigurable], completion: @escaping () -> Void)
    
    func getValue(forConfig config: any FirebaseConfigurable) -> String?
    func updateValue(forConfig config: any FirebaseConfigurable, newValue: String?)
}

public extension RemoteConfigManager {
    var kInstallURL: String {
        return "install_server_path"
    }
    
    var kPurchaseURL: String {
        return "purchase_server_path"
    }
}
