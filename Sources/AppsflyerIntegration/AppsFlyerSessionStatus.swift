import Foundation

/// The `appsflyerSession` value of the configuration status. Starts of different foreground cycles
/// can overlap and finish in any order, so a rejected later start must not hide one still in flight.
struct AppsFlyerSessionStatus {
    private var didStart = false
    private var pendingStarts = 0
    private var lastError: NSError?

    var value: String {
        if didStart {
            return "started"
        }
        if pendingStarts > 0 {
            return "starting"
        }
        if let lastError {
            return "error: \(lastError.domain) \(lastError.code)"
        }
        return "not started"
    }

    mutating func startBegan() {
        pendingStarts += 1
    }

    mutating func startFinished(error: Error?) {
        pendingStarts = max(pendingStarts - 1, 0)
        if let error {
            lastError = error as NSError
        } else {
            didStart = true
        }
    }
}
