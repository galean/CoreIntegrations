struct AppsFlyerSessionStartPolicy {
    private var isReady = false
    private var didStart = false

    /*
     The SDK fires the readiness listener on every activation of the same foreground cycle -
     ATT alert dismissal, Control Center - not once per cycle as its header claims. A second
     `start()` in the same cycle either sends a duplicate session or, inside
     `minTimeBetweenSessions`, fails. So readiness alone does not reopen the start: one start
     per foreground cycle, reopened only by the background transition.
     */
    mutating func sessionBecameReady() {
        isReady = true
    }

    mutating func sessionBecameUnavailable() {
        isReady = false
        didStart = false
    }

    mutating func claimStart() -> Bool {
        guard isReady, didStart == false else {
            return false
        }

        didStart = true
        return true
    }
}
