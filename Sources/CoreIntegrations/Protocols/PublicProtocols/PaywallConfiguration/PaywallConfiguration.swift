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
        guard let offerings = CoreManager.shared.storedOfferings(), let offering = offerings[self.id] else {return []}
        var subscriptions:[Purchase]?
        offering.availablePackages.forEach { package in
            let subscription = Purchase(package: package)
            subscriptions?.append(subscription)
        }
        return subscriptions ?? []
    }
    
    func purchases(completion: @escaping ([Purchase]?) -> Void) {
        CoreManager.shared.offerings { offerings in
            guard let offering = offerings?[self.id] else {completion(nil); return}
            var subscriptions:[Purchase]?
            offering.availablePackages.forEach { package in
                let subscription = Purchase(package: package)
                subscriptions?.append(subscription)
            }
            completion(subscriptions)
        }
    }
}
