import UIKit

public protocol AppfslyerManagerProtocol {
    var appsflyerID: String { get }
    var customerUserID: String? { get set }
    var deeplinkResult: [String: String]? { get }
    var delegate: AppsflyerManagerDelegate? { get set }
    
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] )
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    
    func startAppsflyer()
    func logTrialPurchase()
}
