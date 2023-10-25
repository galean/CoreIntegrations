//
//  File.swift
//  
//
//  Created by Andrii Plotnikov on 16.09.2023.
//

import Foundation

public protocol PurchasesManagerProtocol {
    init(subscriptionSecret: String)
    func completeTransaction()
    func purchase(_ purchaseID: String, quantity: Int, atomically: Bool,
                  completion: @escaping (_ result: PurchasesPurchaseResult) -> Void)
    func verifyPremium(premiumSubscriptionIds: Set<String>,
                       premiumPurchaseIds: Set<String>,
                       completion: @escaping (_ result: PurchasesVerifyPremiumResult) -> Void)
    func restore(subscriptionIds: Set<String>,
                 purchaseIds: Set<String>,
                 completion: @escaping (_ result: PurchasesVerifyResult) -> Void)
}
