//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 16/11/23.
//

import Foundation
import RevenueCat

public enum RevenueCatOfferingsResult {
    case success(offerings: Offerings)
    case error(error: String)
}
