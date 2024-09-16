
import Foundation

public struct FacebookPurchaseData {
    let isTrial: Bool
    let subcriptionID: String
    let trialPrice: Double
    let price: Double
    let currencyCode: String
    
    public init(isTrial: Bool, subcriptionID: String, trialPrice: Double, price: Double, currencyCode: String) {
        self.isTrial = isTrial
        self.subcriptionID = subcriptionID
        self.trialPrice = trialPrice
        self.price = price
        self.currencyCode = currencyCode
    }
}
