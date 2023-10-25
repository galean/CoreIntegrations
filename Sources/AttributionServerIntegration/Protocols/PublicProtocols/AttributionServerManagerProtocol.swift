//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation

public protocol AttributionServerManagerProtocol {
    static var shared: AttributionServerManager { get }
    var uniqueUserID: String? { get }
    var savedUserUUID: String? { get }
    var installResultData: AttributionManagerResult? { get }

    func configure(config: AttributionConfigData)
    func syncOnAppStart(_ completion: @escaping (AttributionManagerResult?) -> Void)
    func syncInstall(_ completion: @escaping (AttributionManagerResult?) -> Void)
    func syncPurchase(data: AttributionPurchaseModel)
}
