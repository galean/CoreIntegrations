
import Foundation
#if !COCOAPODS
import FirebaseIntegration
#endif

public protocol CoreRemoteDataSource {
    associatedtype CoreRemoteConfigs: CoreRemoteConfigurable
    associatedtype CoreRemoteABTests: CoreRemoteABTestable
    
    var allConfigs: [CoreRemoteConfigs] { get }
    var allABTests: [CoreRemoteABTests] { get }
    
    var allRemoteKeys: [String] { get }
    var allConfigurables: [any CoreFirebaseConfigurable] { get }
}

public extension CoreRemoteDataSource {
    var allConfigs: [CoreRemoteConfigs] {
        return CoreRemoteConfigs.allCases as! [Self.CoreRemoteConfigs]
    }

    var allABTests: [CoreRemoteABTests] {
        return CoreRemoteABTests.allCases as! [Self.CoreRemoteABTests]
    }
    
    var allRemoteKeys: [String] {
        let allConfigKeys: [String] = allConfigs.map { $0.key }
        let allABTestKeys: [String] = allABTests.map { $0.key }
        let allRemoteKeys = allConfigKeys + allABTestKeys
        return allRemoteKeys
    }
    
    var allConfigurables: [any CoreFirebaseConfigurable] {
        let allConfigurables: [any CoreFirebaseConfigurable] = allConfigs + allABTests
        return allConfigurables
    }
}

