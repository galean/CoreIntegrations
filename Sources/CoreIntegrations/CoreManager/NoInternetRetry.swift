/// The one retry after `.noInternet` (China, first launch, both services failed).
struct NoInternetRetry {
    private enum State {
        case idle, waiting, retried
    }

    private(set) var isOptedOut = false
    private var state = State.idle

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

    mutating func claimRetry() -> Bool {
        guard state == .waiting else {
            return false
        }
        state = .retried
        return true
    }
}
