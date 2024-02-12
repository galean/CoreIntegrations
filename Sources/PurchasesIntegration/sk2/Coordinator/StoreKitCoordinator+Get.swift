import Foundation
import StoreKit

extension StoreKitCoordinator {

    public func requestProducts(_ identifiers: [String]) async -> SKProductsResult {
        debugPrint("\(StoreKitCoordinator.identifier) requestProducts \(DebuggingIdentifiers.actionOrEventInProgress) Requesting products... \(DebuggingIdentifiers.actionOrEventInProgress)")
        guard !identifiers.isEmpty else {
            debugPrint("\(StoreKitCoordinator.identifier) requestProducts \(DebuggingIdentifiers.actionOrEventFailed) Failed: identifiers are empty.")
            return .error(error: "empty identifiers")
        }
        
        do {
            // Request products from the App Store using the identifiers that the Products.plist file defines.
            let storeProducts = try await Product.products(for: identifiers)
            debugPrint("\(StoreKitCoordinator.identifier) requestProductsForPaywall \(DebuggingIdentifiers.actionOrEventSucceded) Completed gathering Products.")

            debugPrint("\(StoreKitCoordinator.identifier) requestProductsForPaywall \(DebuggingIdentifiers.actionOrEventSucceded) Completed updating available Products.")
            return .success(products: storeProducts)
        } catch {
            debugPrint("\(StoreKitCoordinator.identifier) requestProductsForPaywall \(DebuggingIdentifiers.actionOrEventFailed) Failed product request from the App Store server: \(error).")
            return .error(error: error.localizedDescription)
        }
    }
    
    public func requestAllProducts(_ identifiers: [String]) async -> SKProductsResult {
        debugPrint("\(StoreKitCoordinator.identifier) requestProducts \(DebuggingIdentifiers.actionOrEventInProgress) Requesting products... \(DebuggingIdentifiers.actionOrEventInProgress)")
        guard !identifiers.isEmpty else {
            debugPrint("\(StoreKitCoordinator.identifier) requestProducts \(DebuggingIdentifiers.actionOrEventFailed) Failed: identifiers are empty.")
            return .error(error: "empty identifiers")
        }
        
//        ???
//        if !allAvailableProducts.isEmpty {
//            return .success(products: allAvailableProducts)
//        }
        
        do {
            // Request products from the App Store using the identifiers that the Products.plist file defines.
            let storeProducts = try await Product.products(for: identifiers)
            debugPrint("\(StoreKitCoordinator.identifier) requestProducts \(DebuggingIdentifiers.actionOrEventSucceded) Completed gathering Products.")
            
            allAvailableProducts = storeProducts
            
            mapProducts(storeProducts)

            debugPrint("\(StoreKitCoordinator.identifier) requestProducts \(DebuggingIdentifiers.actionOrEventSucceded) Completed updating available Products.")
            return .success(products: storeProducts)
        } catch {
            debugPrint("\(StoreKitCoordinator.identifier) requestProducts \(DebuggingIdentifiers.actionOrEventFailed) Failed product request from the App Store server: \(error).")
            return .error(error: error.localizedDescription)
        }
    }
    
    func mapProducts(_ storeProducts: [Product]) {
        var newConsumables: [Product] = []
        var newNonConsumables: [Product] = []
        var newSubscriptions: [Product] = []
        var newNonRenewables: [Product] = []

        // Filter the products into categories based on their type.
        for product in storeProducts {
            switch product.type {
            case .consumable:
                newConsumables.append(product)
                debugPrint("\(StoreKitCoordinator.identifier) requestProducts \(DebuggingIdentifiers.actionOrEventSucceded) Found consumable : \(product).")
            case .nonConsumable:
                newNonConsumables.append(product)
                debugPrint("\(StoreKitCoordinator.identifier) requestProducts \(DebuggingIdentifiers.actionOrEventSucceded) Found non-consumable : \(product).")
            case .autoRenewable:
                newSubscriptions.append(product)
                debugPrint("\(StoreKitCoordinator.identifier) requestProducts \(DebuggingIdentifiers.actionOrEventSucceded) Found auto-renewable subscription : \(product).")
            case .nonRenewable:
                debugPrint("\(StoreKitCoordinator.identifier) requestProducts \(DebuggingIdentifiers.actionOrEventSucceded) Found non-renewable subscription : \(product).")
                newNonRenewables.append(product)
            default:
                // Ignore this product.
                debugPrint("\(StoreKitCoordinator.identifier) requestProducts \(DebuggingIdentifiers.actionOrEventFailed) unknown product : \(product).")
            }
        }

        debugPrint("\(StoreKitCoordinator.identifier) requestProducts \(DebuggingIdentifiers.actionOrEventSucceded) Completed ordering Products.")

        // Sort each product category by price, lowest to highest, to update the store.
        consumables = sortByPrice(newConsumables)
        nonConsumables = sortByPrice(newNonConsumables)
        subscriptions = sortByPrice(newSubscriptions)
        nonRenewables = sortByPrice(newNonRenewables)
    }

    private func sortByPrice(_ products: [Product]) -> [Product] {
        products.sorted(by: { return $0.price < $1.price })
    }

}
