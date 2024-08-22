
import Foundation

public protocol CoreSettingsProtocol: AnyObject {
    var appID: String { get }
    var appsFlyerKey: String { get }
    var attributionServerSecret: String { get }
    var growthBookClientKey: String? { get }
    var subscriptionsSecret: String { get }
    
    var amplitudeSecret: String { get }
    
    var launchCount: Int { get set }
    
    var paywallSourceForRestricted: CoreUserSource? { get }
}

public extension CoreSettingsProtocol {
    var isFirstLaunch: Bool {
        launchCount == 1
    }
    var growthBookClientKey: String? {
        return nil
    }
    
    var paywallSourceForRestricted: CoreUserSource? {
        return nil
    }
}
