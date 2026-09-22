
import UIKit

#if !COCOAPODS
import PurchasesIntegration
import AppsflyerIntegration
import AttributionServerIntegration
import AnalyticsIntegration
import SentryIntegration
import AttestationIntegration
#endif
import AppTrackingTransparency
import StoreKit

public protocol CoreManagerProtocol {
    static var shared: CoreManagerProtocol { get }
        
    static var uniqueUserID: String? { get }
    static var sentry:PublicSentryManagerProtocol { get }
    
    var fcmToken: String? { get }
    var userInfo: UserInfo? { get }

    @MainActor
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

    func handleCustomFirebaseConfigured()
    /// Applies a change of the user's advertising data sharing choice made while the app is running.
    /// The launch value comes from `CoreConfigurationProtocol.isAdPartnersDataSharingEnabled`;
    /// calling this before the framework is configured has no effect.
    func setAdPartnersDataSharingEnabled(_ isEnabled: Bool)
    
    func setExternalAuthId(_ externalAuthId: String?)
    
    @MainActor
    func listenForPendingPurchases(_ result: @escaping (PurchasesIntegration.Transaction?, Error?) -> Void)

    func purchase(_ purchase: Purchase, activeController: UIViewController?) async throws -> PurchasesPurchaseResult
    
    func purchase(_ purchase: Purchase, promoOffer: PromoOffer, activeController: UIViewController?) async throws -> PurchasesPurchaseResult
        
    func handleSuccessfulPurchase(product: Product, purchaseInfo: SKPurchaseInfo)
    
    func verifyPremium() async -> PurchasesVerifyPremiumResult
    
    func verifyAll() async -> PurchaseVerifyAllResult
    
    func restore() async -> PurchasesRestoreResult
    
    func restoreAll() async -> PurchasesRestoreResult
    
    func startSessionReplayRecord()
    
    func stopSessionReplayRecord()
    
}

public struct UserInfo: Codable {
    public var userSource: CoreUserSource
    public var isIPAT: Bool?
    public var attrInfo: [String: String]?
    
    public init(userSource: CoreUserSource, isIPAT: Bool?, attrInfo: [String : String]? = nil) {
        self.userSource = userSource
        self.isIPAT = isIPAT
        self.attrInfo = attrInfo
    }
    
    public var confidentIPAT: Bool {
        return isIPAT != false
    }
}
