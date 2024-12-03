
import Foundation

#if !COCOAPODS
import Experiment
import RemoteTestingIntegration
#else
import AmplitudeExperiment
#endif



public protocol CoreRemoteABTestable: CaseIterable, ExtendedRemoteConfigurable {
    static var ab_paywall_fb: Self { get }
    static var ab_paywall_google: Self { get }
    static var ab_paywall_asa: Self { get }
    static var ab_paywall_organic: Self { get }
}
