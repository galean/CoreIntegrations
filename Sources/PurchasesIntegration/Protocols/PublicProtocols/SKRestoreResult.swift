//
//  SKRestoreResult.swift
//
//
//  Created by Anatolii Kanarskyi on 8/2/24.
//

import Foundation
import StoreKit

public enum SKRestoreResult {
    case restore(consumables: [Product], nonConsumables : [Product], subscriptions: [Product], nonRenewables: [Product])
    case error(_ error: String)
}
