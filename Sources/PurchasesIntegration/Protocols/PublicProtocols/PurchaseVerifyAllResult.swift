//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation
import StoreKit

public enum PurchaseVerifyAllResult {
    case success(consumables: [Purchase], nonConsumables : [Purchase], subscriptions: [Purchase], nonRenewables: [Purchase])
}
