//
//  PaywallConfiguration.swift
//  
//
//  Created by Anatolii Kanarskyi on 15/11/23.
//

import Foundation

public protocol CorePaywallConfiguration: CaseIterable {
    var id: String { get }
}

public extension CorePaywallConfiguration {
    static func ==(lhs: any CorePaywallConfiguration, rhs: any CorePaywallConfiguration) -> Bool {
        return lhs.id == rhs.id
    }
    
    //add error to result
    func purchases(completion: @escaping ([Purchase]?) -> Void) {
        CoreManager.internalShared.purchases(config: self) { purchases in
            completion(purchases)
        }
    }
    //add async await
}
