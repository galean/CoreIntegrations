//
//  SKVerifyPremiumResult.swift
//
//
//  Created by Anatolii Kanarskyi on 22/2/24.
//

import Foundation
import StoreKit

public enum SKVerifyPremiumResult {
    case premium(purchase: Product)
    case notPremium
}
