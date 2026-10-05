import UIKit

public protocol AppfslyerManagerProtocol {
    var appsflyerID: String { get }
    var customerUserID: String? { get set }
    var deeplinkResult: [String: String]? { get }
    var delegate: AppsflyerManagerDelegate? { get set }
    var deeplinkError: Error? { get }
    /// Derived from the `start()` completions of this process, for analytics only.
    var appsflyerSession: AppsFlyerSessionState { get }
    /// `true` once a successful conversion result was delivered in this process.
    var didDeliverConversionData: Bool { get }
    
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] )
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    
    /// Signals that the customer user ID is set, i.e. the session may be sent.
    func startAppsflyer()
    /// Signals that the ATT decision is known, i.e. the session may be sent.
    func handleATTResolved()
    func setAdPartnersDataSharingEnabled(_ isEnabled: Bool)
    func logTrialPurchase()
}
