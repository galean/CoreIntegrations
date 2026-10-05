import Foundation

public enum AppsFlyerSessionState: String {
    case started
    case starting
    case failed
    case notStarted = "not started"
}

public struct AppsFlyerStartAttempt {
    /// 1-based number of the `start()` call in this process.
    public let number: Int
    /// `nil` for the first call in this process.
    public let secondsSincePreviousAttempt: TimeInterval?
    /// The SDK refused the call locally because it came within `minTimeBetweenSessions` of the
    /// previous session it sent. Expected, not a failure of the session.
    public let isRateLimited: Bool
}

extension AppsFlyerStartAttempt {
    /*
     `com.appsflyer.sdk.event` / 10 is undocumented, measured on SDK 7.0.1: an instant local
     rejection with no network and no SDK state change. Should the SDK ever change it, the
     rejection is classified as a plain error again - noisier, but no signal is lost.
     */
    init(number: Int, secondsSincePreviousAttempt: TimeInterval?, error: Error) {
        let error = error as NSError
        self.init(number: number,
                  secondsSincePreviousAttempt: secondsSincePreviousAttempt,
                  isRateLimited: error.domain == "com.appsflyer.sdk.event" && error.code == 10)
    }
}

/*
 Process-wide outcome of our `start()` calls, for reporting only - nothing waits on it. A
 completion is not final for the session: after a transport failure the SDK re-sends the
 cached launch with the next `start()` or event, and a completion may arrive much later or never.
 */
struct AppsFlyerSessionTally {
    private var started = 0
    private var failed = 0
    private var inFlight = 0
    private var lastStartDate: Date?

    var state: AppsFlyerSessionState {
        if started > 0 {
            return .started
        }
        if inFlight > 0 {
            return .starting
        }
        if failed > 0 {
            return .failed
        }
        return .notStarted
    }

    /// Returns the 1-based number of this call - every call sits in exactly one counter - and
    /// the time since the previous one.
    mutating func beginStart(at date: Date) -> (number: Int, secondsSincePreviousAttempt: TimeInterval?) {
        defer { lastStartDate = date }
        inFlight += 1
        return (started + failed + inFlight, lastStartDate.map { date.timeIntervalSince($0) })
    }

    mutating func finishStart(succeeded: Bool) {
        if succeeded {
            started += 1
        } else {
            failed += 1
        }
        inFlight -= 1
    }
}
