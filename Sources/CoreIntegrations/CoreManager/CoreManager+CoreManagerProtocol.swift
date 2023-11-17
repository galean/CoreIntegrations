//
//  CoreManager+CoreManagerProtocol.swift
//
//
//  Created by Andrii Plotnikov on 02.10.2023.
//

import Foundation
import UIKit
import AppTrackingTransparency
import RevenueCatIntegration
import RevenueCat

extension CoreManager: CoreManagerProtocol {
    
    public func application(_ application: UIApplication,
                            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?,
                            coreCofiguration configuration: CoreConfigurationProtocol,
                            coreDelegate delegate: CoreManagerDelegate) {
        self.delegate = delegate
        configureAll(configuration: configuration)
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        appsflyerManager?.application(app, open: url, options: options)
        return (facebookManager?.application(app, open: url, options: options) ?? false)
    }
    
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        appsflyerManager?.application(application, continue: userActivity, restorationHandler: restorationHandler) ?? false
    }
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        appsflyerManager?.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        appsflyerManager?.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    public func handleATTPermission(_ status: ATTrackingManager.AuthorizationStatus) {
        self.sendAttEvent(answer: status == .authorized)
        self.handleATTAnswered(status)
        InternalConfigurationEvent.attConcentGiven.markAsCompleted()
    }
    
    public func purchase(_ purchase: Purchase) async -> RevenueCatPurchaseResult {
        guard let revenueCatManager else {
            assertionFailure()
            return .error(error: "Integration error")
        }
        
        let result = await revenueCatManager.purchase(purchase.package)
        switch result {
        case .success(let details):
            self.handlePurchaseSuccess(purchaseInfo: details)
        default:
            break
        }
        
        return result
    }
    
    public func purchase(_ purchase: Purchase, completion: @escaping (RevenueCatIntegration.RevenueCatPurchaseResult) -> Void) {
        guard let revenueCatManager else {
            assertionFailure()
            completion(.error(error: "Integration error"))
            return
        }
        
        revenueCatManager.purchase(purchase.package) { result in
            switch result {
            case .success(let details):
                self.handlePurchaseSuccess(purchaseInfo: details)
                self.sendSubscriptionTypeUserProperty(identifier: details.productID)
            default:
                break
            }
            completion(result)
        }
    }
    
    public func verifyPremium(completion: @escaping (_ result: RevenueCatVerifyPremiumResult) -> Void) {
        guard let revenueCatManager else {
            assertionFailure()
            completion(.error)
            return
        }
        revenueCatManager.verifyPremium { result in
            switch result {
            case .premium(let subscriptionID):
                self.sendSubscriptionTypeUserProperty(identifier: subscriptionID)
            default:
                break
            }
            completion(result)
        }
        revenueCatManager.verifyPremium(completion: completion)
    }
    
    public func restorePremium(completion: @escaping (_ result: RevenueCatVerifyPremiumResult) -> Void) {
        guard let revenueCatManager else {
            assertionFailure()
            completion(.error)
            return
        }
        revenueCatManager.restorePremium(completion: completion)
    }
    
    public func verifyPurchases(completion: @escaping (_ result: RevenueCatRestoreResult) -> Void) {
        guard let revenueCatManager else {
            assertionFailure()
            completion(.error)
            return
        }
        
        revenueCatManager.verifyPurchases(completion: completion)
    }
    
    public func restorePurchases(completion: @escaping (_ result: RevenueCatRestoreResult) -> Void) {
        guard let revenueCatManager else {
            assertionFailure()
            completion(.error)
            return
        }
        
        revenueCatManager.restorePurchases(completion: completion)
    }
    
}
