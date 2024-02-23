//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 21/2/24.
//

import Foundation

public protocol CorePurchaseIdentifier: CaseIterable {
    var id: String { get }
    var purchaseGroup: any CorePurchaseGroup { get }
}
