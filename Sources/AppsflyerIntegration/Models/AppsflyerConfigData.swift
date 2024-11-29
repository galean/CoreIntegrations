import AppsFlyerLib

public struct AppsflyerConfigData {
    let appsFlyerDevKey: String
    let appleAppID: String
    
    public init(appsFlyerDevKey: String, appleAppID: String) {//}, timeoutInterval: TimeInterval = 30) {
        self.appsFlyerDevKey = appsFlyerDevKey
        self.appleAppID = appleAppID
    }
}
