
import Foundation

public class CoreRemoteConfigManager {
    public private(set) var remoteConfigResult: [String: String]? = nil
    public private(set) var internalConfigResult: [String: String]? = nil
    public private(set) var install_server_path: String? = nil
    public private(set) var purchase_server_path: String? = nil
    public private(set) var config_on: Bool = false
    
    private let kInstallURL = "install_server_path"
    private let kPurchaseURL = "purchase_server_path"
    
    private let firebaseManager = FirebaseManager()
    private var isConfigured:Bool = false
    private var isConfigFetched:Bool = false
    
    public func configure(id:String, completion: @escaping () -> Void) {
        guard !isConfigured else {
            return
        }
        
        firebaseManager.configure() { [weak self] in
            completion()
            self?.firebaseManager.setUserID(id)
            self?.isConfigured = true
        }
    }
    
    public func fetchRemoteConfig(_ appConfigurables: [any FirebaseConfigurable], completion: @escaping () -> Void) {
        guard !isConfigFetched else {
            completion()
            return
        }
        
        firebaseManager.fetchRemoteConfig(appConfigurables) { [weak self] in
            guard let self = self else {return}
            
            remoteConfigResult = firebaseManager.remoteConfigResult
            internalConfigResult = firebaseManager.internalConfigResult
            
            install_server_path = firebaseManager.install_server_path
            purchase_server_path = firebaseManager.purchase_server_path
            config_on = firebaseManager.config_on
            
            isConfigFetched = true
            completion()
        }
    }
}
