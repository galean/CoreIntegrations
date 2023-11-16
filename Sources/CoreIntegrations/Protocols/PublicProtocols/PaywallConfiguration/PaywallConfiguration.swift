//
//  PaywallConfiguration.swift
//  
//
//  Created by Anatolii Kanarskyi on 15/11/23.
//

import Foundation

public protocol PaywallConfiguration: CaseIterable {
    var id: String { get }
}

public extension PaywallConfiguration {
    static func ==(lhs: any PaywallConfiguration, rhs: any PaywallConfiguration) -> Bool {
        return lhs.id == rhs.id
    }
    
    var purchases: [Purchase] {
        return CoreManager.shared.storedPurchases(config: self)
    }
    
    func purchases(completion: @escaping ([Purchase]?) -> Void) {
        CoreManager.shared.purchases(config: self) { purchases in
            completion(purchases)
        }
    }
}
