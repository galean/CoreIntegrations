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
    func verifyPremium() async
    func purchase(_ product: Product) async throws -> Transaction?
    func restore() async -> Bool
    func isPurchased(_ product: Product) async throws -> Bool
}
