//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 21/2/24.
//

import Foundation

public protocol CorePurchaseGroup: Equatable, CaseIterable, RawRepresentable where RawValue == String {
    static var Pro: Self { get }
}

public extension CorePurchaseGroup {
    static func ==(lhs: any CorePurchaseGroup, rhs: any CorePurchaseGroup) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    var isPro: Bool {
        switch self {
        case .Pro:
            return true
        default:
            return false
        }
    }
}
