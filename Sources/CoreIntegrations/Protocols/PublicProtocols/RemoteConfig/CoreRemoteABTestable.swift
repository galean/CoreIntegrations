//
//  CoreRemoteABTestable.swift
//  
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation

#if !COCOAPODS
import Experiment
#else
import AmplitudeExperiment
#endif

public protocol CoreRemoteABTestable: CaseIterable, CoreFirebaseConfigurable {
    static var ab_paywall_fb: Self { get }
    static var ab_paywall_google: Self { get }
    static var ab_paywall_asa: Self { get }
    static var ab_paywall_organic: Self { get }
}
