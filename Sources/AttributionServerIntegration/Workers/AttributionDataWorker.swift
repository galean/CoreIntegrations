//
//  TLMAttributionManagerDataWorker.swift
//  
//
//  Created by Andrii Plotnikov on 22.12.2022.
//

import Foundation
import AdSupport
import StoreKit

#if canImport(iAd)
import iAd
#endif

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
        var uuid = UIDevice.current.identifierForVendor?.uuidString ?? ""
        return uuid
    }
    
    var uuid: String {
        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let range = idfv.index(idfv.startIndex, offsetBy: 14)
        return idfv.replacingCharacters(in: range...range, with: "F")
    }
    
    var sdkVersion: String {
        return "1.0.8f"
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
        let enabled = ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        return enabled
    }
    var attributionDetails: [String: String]? {
        var dataResult: [String: String]?
        let sema = DispatchSemaphore(value: 0)
        ADClient.shared().requestAttributionDetails { (data, error) in
            if let details = data, let dict = details[(data?.keys.first)!] as? [String:String] {
                dataResult = dict
            }
            sema.signal()
        }
        
        sema.wait()
        return dataResult
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
                print(receiptData)

                let receiptString = receiptData.base64EncodedString(options: [])
                return receiptString
            }
            catch {
                print("Couldn't read receipt data with error: " + error.localizedDescription)
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
        guard var uuid = uuidString else {
            return ""
        }
        
        return uuid
    }
}
