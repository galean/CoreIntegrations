//
//  CorePaywallDataSource.swift
//
//
//  Created by Anatolii Kanarskyi on 15/11/23.
//

import Foundation

public protocol CorePaywallDataSource {
    associatedtype PaywallInitialConfiguration: CorePaywallConfiguration
    
    var allConfigs: [PaywallInitialConfiguration] { get }
}

public extension CorePaywallDataSource {
    var allConfigs: [PaywallInitialConfiguration] {
        return PaywallInitialConfiguration.allCases as! [Self.PaywallInitialConfiguration]
    }
}
