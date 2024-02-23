//
//  PurchasesRestoreResult.swift
//
//
//  Created by Anatolii Kanarskyi on 8/2/24.
//

import Foundation
import StoreKit

public enum PurchasesRestoreResult {
    case restore(consumables: [Purchase], nonConsumables : [Purchase], subscriptions: [Purchase], nonRenewables: [Purchase])
    case error(_ error: String)
}
