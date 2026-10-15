import UIKit

public protocol AppfslyerManagerProtocol {
    var appsflyerID: String { get }
    /// A non-nil value lets the session start (one of its conditions).
    var customerUserID: String? { get set }
    var deeplinkResult: [String: String]? { get }
    var delegate: AppsflyerManagerDelegate? { get set }
    var deeplinkError: Error? { get }
    /// `not started` / `starting` / `started` / `error: <domain> <code>`, for the configuration status. Main thread only.
    var sessionStatus: String { get }
    
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] )
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    
    /// The ATT decision is known: one of the session start conditions.
    func handleATTResolved()
    func setAdPartnersDataSharingEnabled(_ isEnabled: Bool)
    func logTrialPurchase()
}
