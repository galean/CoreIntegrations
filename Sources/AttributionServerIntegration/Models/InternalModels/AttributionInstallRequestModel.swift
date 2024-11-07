
import Foundation

internal struct AttributionInstallRequestModel: Codable {
    let userId: String
    let idfa: String?
    let sdkVersion: String
    let osVersion: String
    let appVersion: String
    let limitAdTracking: Bool
    let storeCountry: String?
    let appsflyerId: String?
    let iosATT: UInt?
    let fb: FBFields?
    let sa: SAFields?
    
    internal struct FBFields: Codable {
        let userId: String
        let userData: String
        let anonymousId: String
    }
    
    internal struct SAFields: Codable {
        let attribution: Bool
        let orgName: String
        let orgId: String
        let campaignName: String
        let campaignId: String
        let purchaseDate: String
        let conversionDate: String
        let conversionType: String
        let clickDate: String
        let adGroupId: String
        let adGroupName: String
        let region: String
        let keyword: String
        let keywordId: String
        let keywordMatchType: String
        let creativeSetId: String
        let creativeSetName: String
        let token: String
        
        let adId: String
        
        init(data:[String:Any]) {
            attribution = data["attribution"] as? Bool ?? false
            orgId = DictValue.toString(data["orgId"])
            campaignId = DictValue.toString(data["campaignId"])
            conversionType = DictValue.toString(data["conversionType"])
            adGroupId = DictValue.toString(data["adGroupId"])
            keywordId = DictValue.toString(data["keywordId"])
            region = DictValue.toString(data["countryOrRegion"])
            adId = DictValue.toString(data["adId"])
            clickDate = DictValue.toString(data["clickDate"])
            
            orgName = DictValue.toString(data["orgName"])
            campaignName = DictValue.toString(data["campaignName"])
            purchaseDate = DictValue.toString(data["purchaseDate"])
            conversionDate = DictValue.toString(data["conversionDate"])
            adGroupName = DictValue.toString(data["adGroupName"])
            keyword = DictValue.toString(data["keyword"])
            keywordMatchType = DictValue.toString(data["keywordMatchtype"])
            creativeSetId = DictValue.toString(data["creativesetId"])
            creativeSetName = DictValue.toString(data["creativesetName"])
            token = DictValue.toString(data["token"])
        }
        
         struct DictValue {
            static func toString(_ value: Any?) -> String {
                if let value = value as? String {
                    return value
                }else if let value = value as? Int, value != 1234567890, value != 12323222 {
                    return String(value)
                } else {
                    return "\(value ?? "")"
                }
            }
        }
        
        init(token: String) {
            attribution = false
            orgName = ""
            orgId = ""
            campaignName = ""
            campaignId = ""
            purchaseDate = ""
            conversionDate = ""
            conversionType = ""
            clickDate = ""
            adGroupId = ""
            adGroupName = ""
            region = ""
            keyword = ""
            keywordId = ""
            keywordMatchType = ""
            creativeSetId = ""
            creativeSetName = ""
            adId = ""
            self.token = token
        }
    }
}
