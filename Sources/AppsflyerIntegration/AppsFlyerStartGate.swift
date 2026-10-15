/// When the framework sends the AppsFlyer session. SDK 7 no longer waits for ATT itself, so the
/// session starts once per foreground cycle when every condition holds.
struct AppsFlyerStartGate {
    var isATTResolved = false
    /// Set by the SDK session ready listener, which fires on every activation of a foreground cycle.
    var isSessionReady = false
    private var didStartThisCycle = false

    mutating func enteredBackground() {
        isSessionReady = false
        didStartThisCycle = false
    }

    /// `hasCustomerUserID` is read from the SDK at the moment of the check.
    mutating func claimStart(hasCustomerUserID: Bool) -> Bool {
        guard isATTResolved, hasCustomerUserID, isSessionReady, didStartThisCycle == false else {
            return false
        }
        didStartThisCycle = true
        return true
    }
}
