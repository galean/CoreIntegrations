//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 15/2/24.
//

import Foundation
import StoreKit

public protocol PurchasesManagerProtocol {
    static var shared: PurchasesManagerProtocol { get }

    func initialize(allIdentifiers: [String], proIdentifiers: [String])
    func setUserID(_ id: String)
    func requestProducts(_ identifiers: [String]) async -> SKProductsResult
    func requestAllProducts(_ identifiers: [String]) async -> SKProductsResult
    func updateProductStatus() async
    func purchase(_ product: Product) async throws -> SKPurchaseResult
    func purchase(_ product: Product, promoOffer:PromoOffer) async throws -> SKPurchaseResult
    func restore() async -> SKRestoreResult
    func verifyPremium() async -> PurchasesVerifyPremiumResult
}
