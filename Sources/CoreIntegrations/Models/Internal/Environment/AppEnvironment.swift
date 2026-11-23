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

    /// The App Store storefront is in the EEA, United Kingdom or Switzerland.
    public static var isEU: Bool {
        get async {
            guard let storefront = await Storefront.current else {
                return false
            }

            let countryCodes: Set<String> = [
                "AUT", "BEL", "BGR", "HRV", "CYP", "CZE", "DNK", "EST", "FIN", "FRA",
                "DEU", "GRC", "HUN", "ISL", "IRL", "ITA", "LVA", "LIE", "LTU", "LUX",
                "MLT", "NLD", "NOR", "POL", "PRT", "ROU", "SVK", "SVN", "ESP", "SWE",
                "GBR", "CHE"
            ]
            return countryCodes.contains(storefront.countryCode)
        }
    }
}
