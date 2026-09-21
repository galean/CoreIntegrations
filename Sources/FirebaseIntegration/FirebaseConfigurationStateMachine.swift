
import FirebaseAnalytics
import FirebaseCore
import FirebaseMessaging

public class FirebaseConfigurationStateMachine: NSObject {
    enum State {
        case notSet
        case waitingForExternalConfiguration(id: String?)
        case configuredInternally
        case configuredExternally
        case finishedConfigurationWithID(id: String)
    }
      
    public enum Event {
        case configureInternallyIfNeeded
        case waitForExternalConfiguration
        case handleExternalConfigurationFinished
        case handleIDSetup(id: String)
    }
    
    private(set) var state: State = .notSet
    private var savedID: String?
    
    private var isAdPartnersDataSharingEnabled = true

    private var _fcmToken: String?
    private var _userId: String = ""
    
    public var fcmToken: String? {
        return _fcmToken
    }
    
    override public init() {
        super.init()
    }
        
    public func handle(event: Event) {
        switch (state, event) {
            
        case (.notSet, .configureInternallyIfNeeded):
            configureFirebase()
            state = .configuredInternally
        case (_, .configureInternallyIfNeeded):
            break
            
        case (.notSet, .waitForExternalConfiguration):
            state = .waitingForExternalConfiguration(id: nil)
        case (.configuredInternally, .waitForExternalConfiguration):
            assertionFailure("Internal framework error, contact framework maintainer.")
            break
        case (_, .waitForExternalConfiguration):
            break
          
        case (.notSet, .handleExternalConfigurationFinished):
            state = .configuredExternally
            applyConsent()
        case (.waitingForExternalConfiguration(let id), .handleExternalConfigurationFinished):
            applyConsent()
            if let savedId = id {
                _userId = savedId
                sendAnalyticsID(savedId)
                state = .finishedConfigurationWithID(id: savedId)
            } else {
                state = .configuredExternally
            }
        case (.configuredInternally, .handleExternalConfigurationFinished):
            assertionFailure("You forgot to configure framework to expect external configuration and it already configured internally. If not - contact framework maintainer.")
            break
        case (_, .handleExternalConfigurationFinished):
            break
            
        case (.notSet, .handleIDSetup(_)):
            assertionFailure("Internal framework error, contact framework maintainer.")
            break
        case (.waitingForExternalConfiguration, .handleIDSetup(let id)):
            state = .waitingForExternalConfiguration(id: id)
        case (.configuredInternally, .handleIDSetup(let id)),
             (.configuredExternally, .handleIDSetup(let id)):
            _userId = id
            sendAnalyticsID(id)
            state  = .finishedConfigurationWithID(id: id)
        case (.finishedConfigurationWithID(let sentID), .handleIDSetup(let id)):
            guard sentID == id else {
                assertionFailure("Changing id after it's already set is unexpected. Contact framework maintainer if it was intended.")
                return
            }
            break
        }
    }
    
    public func setAdPartnersDataSharingEnabled(_ isEnabled: Bool) {
        isAdPartnersDataSharingEnabled = isEnabled

        switch state {
        case .notSet, .waitingForExternalConfiguration:
            break
        case .configuredInternally, .configuredExternally, .finishedConfigurationWithID:
            applyConsent()
        }
    }

    private func applyConsent() {
        let advertisingConsent: ConsentStatus = isAdPartnersDataSharingEnabled ? .granted : .denied
        Analytics.setConsent([
            .adStorage: advertisingConsent,
            .adUserData: advertisingConsent,
            .adPersonalization: advertisingConsent,
            .analyticsStorage: .granted
        ])
    }

    private func configureFirebase() {
        FirebaseApp.configure()
        applyConsent()
        Analytics.logEvent("Firebase Init", parameters: nil)
        
        // Set messaging delegate to receive FCM token
        Messaging.messaging().delegate = self
    }
    
    private func sendAnalyticsID(_ id: String) {
        Analytics.setUserID(id)
    }
    
    public func registerForRemoteNotifications(deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension FirebaseConfigurationStateMachine: MessagingDelegate {
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        _fcmToken = token
        
        // Notify that FCM token is available
        NotificationCenter.default.post(
            name: NSNotification.Name("FCMTokenUpdated"),
            object: nil,
            userInfo: ["token": token, "userId": _userId]
        )
    }
}
