//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 1/2/24.
//

import Foundation
import StoreKit

public protocol StoreKitCoordinatorProtocol {
    func initialize(identifiers: [String])
    func verifyPremium() async -> PurchasesVerifyPremiumResult
    func purchase(_ product: Product) async throws -> SKPurchaseResult
    func restore() async -> SKRestoreResult
    func isPurchased(_ product: Product) async throws -> Bool
}
