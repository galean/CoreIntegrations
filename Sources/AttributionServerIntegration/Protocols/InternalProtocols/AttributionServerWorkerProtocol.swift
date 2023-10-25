//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation

internal protocol AttributionServerWorkerProtocol {
    func sendInstallAnalytics(parameters: AttributionInstallRequestModel, authToken: AttributionServerToken,
                              completion: @escaping (([String: Any]?) -> Void))
    func sendPurchaseAnalytics(analytics: AttrubutionPurchaseRequestModel,
                               userId: AttributionUserUUID,
                               authToken: AttributionServerToken,
                               completion: @escaping ((Bool) -> Void))
}
