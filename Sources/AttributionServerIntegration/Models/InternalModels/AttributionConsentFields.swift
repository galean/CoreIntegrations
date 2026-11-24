import Foundation

internal struct AttributionConsentFields: Codable, Equatable {
    let gdprApplies: Bool?
    let adUserData: Bool
    let adPersonalization: Bool
    
    /// GDPR (EEA, UK, Switzerland): the user's answer on the consent screen.
    init(adConsent: AttributionAdConsent) {
        gdprApplies = true
        adUserData = adConsent.isAdUserDataGranted
        adPersonalization = adConsent.isAdPersonalizationGranted
    }
    
    /// CCPA (California): the state of the Do Not Sell switch, `false` when it is on.
    /// Sent without `gdprApplies`.
    init(isAdPartnersDataSharingEnabled: Bool) {
        gdprApplies = nil
        adUserData = isAdPartnersDataSharingEnabled
        adPersonalization = isAdPartnersDataSharingEnabled
    }
    
    /// Install request: the GDPR answer when there is one, otherwise the CCPA state when Do Not Sell is on.
    /// `nil` for a user with neither, so the request carries no consent.
    init?(adConsent: AttributionAdConsent?, isAdPartnersDataSharingEnabled: Bool) {
        if let adConsent {
            self.init(adConsent: adConsent)
        } else if !isAdPartnersDataSharingEnabled {
            self.init(isAdPartnersDataSharingEnabled: false)
        } else {
            return nil
        }
    }
}
