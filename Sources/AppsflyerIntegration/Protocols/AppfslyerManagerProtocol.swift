import UIKit

public protocol AppfslyerManagerProtocol {
    var appsflyerID: String { get }
    var customerUserID: String? { get set }
    var deeplinkResult: [String: String]? { get }
    var delegate: AppsflyerManagerDelegate? { get set }
    var deeplinkError: Error? { get }
    
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] )
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    
    /// Signals that the customer user ID is set, i.e. the session may be sent.
    func startAppsflyer()
    /// Signals that the ATT decision is known, i.e. the session may be sent.
    func handleATTResolved()
    /// Blocks or resumes AppsFlyer postbacks to every integrated ad network for this user.
    func setAdPartnersDataSharingEnabled(_ isEnabled: Bool)
    func logTrialPurchase()
}

public extension AppfslyerManagerProtocol {
    func handleATTResolved() {}
    func setAdPartnersDataSharingEnabled(_ isEnabled: Bool) {}
}
