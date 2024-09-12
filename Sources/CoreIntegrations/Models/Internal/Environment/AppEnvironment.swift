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
    
    static var current: AppEnvironment {
        if AppEnvironment.isDebug {
            return .Debug
        } else if AppEnvironment.isTestFlight {
            return .Testing
        } else {
            return .AppStore
        }
    }
    
    static var isChina: Bool {
        if Locale.current.regionCode ?? "" == "CN" { return true }
        if SKPaymentQueue.default().storefront?.countryCode == "CHN" { return true }
        return false
    }
}
