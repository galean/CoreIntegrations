import Foundation
#if !COCOAPODS
import AttributionServerIntegration
import PurchasesIntegration
#endif

extension AttributionPurchaseModel {
    init(_ details: PurchaseDetails) {
        let price = CGFloat(NSDecimalNumber(decimal: details.product.price).floatValue)
        let introductoryPrice: CGFloat?
        
        if let introPrice = details.product.subscription?.introductoryOffer?.price {
            introductoryPrice = CGFloat(NSDecimalNumber(decimal: introPrice).floatValue)
        } else {
            introductoryPrice = nil
        }

        let currencyCode = details.product.priceFormatStyle.currencyCode
        let purchaseID = details.product.id
        
        let jws = details.jws
        let originalTransactionID = details.originalTransactionID
        let decodedTransaction = details.decodedTransaction
        
        self.init(price: price, introductoryPrice: introductoryPrice,
                  currencyCode: currencyCode, subscriptionIdentifier: purchaseID,
                  jws: jws, originalTransactionID: originalTransactionID, decodedTransaction: decodedTransaction)
    }
}
