//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 11.08.2024.
//

import Foundation

public protocol RemoteTestingProcotol {
    var configurationCompletion: (() -> Void)? { get set }
    
    init(deploymentKey: String)
}

public protocol RemoteConfigManager {
    var allRemoteValues: [String: String] { get }
    
    func fetchRemoteConfig(_ appConfigurables: [any RemoteConfigurable], completion: @escaping () -> Void)
    
    func getValue(forConfig config: any RemoteConfigurable) -> String?
    func exposure(forConfig config: RemoteConfigurable)
}
