
import Foundation

#if !COCOAPODS
import RemoteTestingIntegration
#endif

public protocol CoreRemoteDataSource {
    associatedtype CoreRemoteConfigs: CoreRemoteConfigurable
    
    var allConfigs: [CoreRemoteConfigs] { get }
    
    var allRemoteKeys: [String] { get }
}

public extension CoreRemoteDataSource {
    var allConfigs: [CoreRemoteConfigs] {
        return CoreRemoteConfigs.allCases as! [Self.CoreRemoteConfigs]
    }
    
    var allRemoteKeys: [String] {
        let allConfigKeys: [String] = allConfigs.map { $0.key }
        return allConfigKeys
    }
}

