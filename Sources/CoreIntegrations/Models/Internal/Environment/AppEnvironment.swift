import Foundation
import StoreKit

public enum AppEnvironment: String {
    case Debug, Testing, AppStore
    
    private static var isTestFlight: Bool {
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" || Bundle.main.appStoreReceiptURL == nil
    }
    private static var isDebug: Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }
    
    public static var current: AppEnvironment {
        if AppEnvironment.isDebug {
            return .Debug
        } else if AppEnvironment.isTestFlight {
            return .Testing
        } else {
            return .AppStore
        }
    }
    
    public static var isChina: Bool = {
        if #available(iOS 16, *) {
            guard let region = Locale.current.region else {
                return false
            }
            
            return region.identifier == "CN"
        } else {
            return Locale.current.regionCode == "CN"
        }
    }()
}
