import Foundation

public struct FirebasePurchaseData {
    let isTrial: Bool
    let subscriptionID: String
    let trialPrice: Double
    let price: Double
    let currencyCode: String
    
    public init(isTrial: Bool, subscriptionID: String, trialPrice: Double, price: Double, currencyCode: String) {
        self.isTrial = isTrial
        self.subscriptionID = subscriptionID
        self.trialPrice = trialPrice
        self.price = price
        self.currencyCode = currencyCode
    }
}
