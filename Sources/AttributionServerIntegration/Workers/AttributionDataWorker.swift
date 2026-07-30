
import Foundation
import AdSupport
import AdServices
import StoreKit
import AppTrackingTransparency
import LoggingIntegration

class AttributionDataWorker: AttributionDataWorkerProtocol {
    var idfa: String? {
        let idfaOrNil: String?
        // Check if Advertising Tracking is Enabled
        if isAdTrackingEnabled {
            idfaOrNil = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        } else {
            idfaOrNil = nil
        }
        
        return idfaOrNil
    }
    
    var idfv: String? {
        let uuid = UIDevice.current.identifierForVendor?.uuidString ?? ""
        return uuid
    }

    var sdkVersion: String {
        return "3.0.1rc"
    }
    
    var osVersion: String {
        let version = UIDevice.current.systemVersion
        return version
    }
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        return version
    }
    
    var isAdTrackingEnabled: Bool {
        let attStatus = ATTrackingManager.trackingAuthorizationStatus
        return attStatus == .authorized
    }
    

    func attributionDetails() async -> AttributionDetails? {
        guard let attToken = try? AAAttribution.attributionToken() else {
            DebugLogger.log("Failed to retrieve AAAttribution.attributionToken()")
            return nil
        }
        
        return AttributionDetails(details: ["token": attToken], attributionToken: attToken)
    }
    
    var storeCountry: String {
        if #available(iOS 13.0, *) {
            let country = SKPaymentQueue.default().storefront?.countryCode ?? ""
            return country
        }
        
        return ""
    }
    
    var receiptToken: String {
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
            FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {

            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                DebugLogger.log("Receipt data: \(receiptData.count) bytes")

                let receiptString = receiptData.base64EncodedString(options: [])
                return receiptString
            }
            catch {
                DebugLogger.log("Couldn't read receipt data with error: " + error.localizedDescription)
                return ""
            }
        }
        return ""
    }
    
    func generateUniqueToken() -> String {
        let uuidSize = MemoryLayout<uuid_t>.size
        let uuidStringSize = MemoryLayout<uuid_string_t>.size
        let uuidPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: uuidSize)
        let uuidStringPointer = UnsafeMutablePointer<Int8>.allocate(capacity: uuidStringSize)

        uuid_generate_time(uuidPointer)
        uuid_unparse(uuidPointer, uuidStringPointer)

        let uuidString = NSString(utf8String: uuidStringPointer) as String?
        uuidPointer.deallocate()
        uuidStringPointer.deallocate()
        
        assert(uuidString != nil, "uuid (V1 style) failed")
        guard let uuid = uuidString else {
            return ""
        }
        
        return uuid
    }
}
