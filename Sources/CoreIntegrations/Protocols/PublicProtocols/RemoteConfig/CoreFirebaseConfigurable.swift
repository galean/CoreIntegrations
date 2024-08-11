//
//  File.swift
//  
//
//  Created by Anzhy on 20.10.2023.
//

import Foundation
#if !COCOAPODS
import FirebaseIntegration
#endif
import Experiment

public protocol CoreFirebaseConfigurable: CaseIterable, FirebaseConfigurable {
    var boolValue: Bool { get }
    var activeForSources: [CoreUserSource] { get }
}
