//
//  CorePaywallDataSource.swift
//
//
//  Created by Anatolii Kanarskyi on 15/11/23.
//

import Foundation

public protocol CorePaywallDataSource {
    associatedtype PaywallInitialConfiguration: PaywallConfiguration
    
    var all: [PaywallInitialConfiguration] { get }
}

public extension CorePaywallDataSource {
    var all: [PaywallInitialConfiguration] {
        return PaywallInitialConfiguration.allCases as! [Self.PaywallInitialConfiguration]
    }
}
