//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 21/2/24.
//

import Foundation
import StoreKit

public enum SKVerifyResult {
    case success(consumables: [Product], nonConsumables : [Product], subscriptions: [Product], nonRenewables: [Product])
}
