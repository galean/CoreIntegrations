
import Foundation
import UIKit

public protocol FacebookManagerProtocol {
    var userID: String { get set }
    var userData: String { get }
    var anonUserID: String { get }
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] ) -> Bool
    func configureATT(isAuthorized: Bool)
    func sendPurchaseAnalytics(_ analData: FacebookPurchaseData)
}
