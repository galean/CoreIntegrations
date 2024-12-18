
import UIKit

#if !COCOAPODS
import PurchasesIntegration
import AppsflyerIntegration
import AttributionServerIntegration
import AnalyticsIntegration
import FirebaseIntegration
import SentryIntegration
#endif
import AppTrackingTransparency

public protocol CoreManagerProtocol {
    static var shared: CoreManagerProtocol { get }
    static var uniqueUserID: String? { get }
    static var sentry:PublicSentryManagerProtocol { get }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
                     coreCofiguration configuration: CoreConfigurationProtocol,
                     coreDelegate delegate: CoreManagerDelegate)
    
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] ) -> Bool
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    
    func handleATTPermission(_ status: ATTrackingManager.AuthorizationStatus)
    func handleNoInternetAlertWasShown()

    func purchase(_ purchase: Purchase, activeController: UIViewController?) async -> PurchasesPurchaseResult
        
    func verifyPremium() async -> PurchasesVerifyPremiumResult
    
    func verifyAll() async -> PurchaseVerifyAllResult
    
    func restore() async -> PurchasesRestoreResult
    
    func restoreAll() async -> PurchasesRestoreResult
}
