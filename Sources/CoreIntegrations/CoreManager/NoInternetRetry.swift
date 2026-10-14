/// The one retry after `.noInternet` (China, first launch, both services failed).
struct NoInternetRetry {
    enum Trigger {
        /// The app became active. Counts only after a trip to the background since `.noInternet`
        /// (e.g. to Settings), not after a system dialog shown over the app.
        case activation
        /// The network appeared while the app is active.
        case network
    }

    private enum State {
        case idle, waiting, retried
    }

    private(set) var isOptedOut = false
    private var state = State.idle
    private var didEnterBackgroundSinceNoInternet = false

    /// `handleNoInternetAlertWasShown()` before any `.noInternet`: failures finish as `.finished`, no retry.
    mutating func optOut() {
        if state == .idle {
            isOptedOut = true
        }
    }

    mutating func shouldDeliverNoInternet(isChina: Bool, isFirstLaunch: Bool, completedWithNetworkErrors: Bool) -> Bool {
        guard isChina, isFirstLaunch, completedWithNetworkErrors, isOptedOut == false, state == .idle else {
            return false
        }
        state = .waiting
        return true
    }

    mutating func enteredBackground() {
        if state == .waiting {
            didEnterBackgroundSinceNoInternet = true
        }
    }

    mutating func claimRetry(for trigger: Trigger) -> Bool {
        guard state == .waiting else {
            return false
        }
        if trigger == .activation, didEnterBackgroundSinceNoInternet == false {
            return false
        }
        state = .retried
        return true
    }
}
