import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

private func spinMain(for seconds: TimeInterval) {
    RunLoop.main.run(until: Date().addingTimeInterval(seconds))
}

// The framework's default lives in CoreManager+Configuration.swift, which this binary does not compile.
extension ConfigurationEvent {
    func markAsCompleted() {}
}

private enum AppEvent: String, ConfigurationEvent {
    case onboardingLoaded

    var key: String { rawValue }
    var isFirstStartOnly: Bool { false }
    var isRequiredToContunue: Bool { true }
    func markAsCompleted() {}
}

private let allEvents: [any ConfigurationEvent] = InternalConfigurationEvent.allCases + AppEvent.allCases
private let networkError = NSError(domain: "test.network", code: -1009)

private func makeAttempt(timeout: Int = 1,
                         alreadyCompleted: [(event: any ConfigurationEvent, error: Error?)] = []) -> ConfigurationAttempt {
    ConfigurationAttempt(events: allEvents, isFirstStart: true, timeout: timeout, alreadyCompleted: alreadyCompleted)
}

private func completeAll(_ attempt: ConfigurationAttempt) {
    InternalConfigurationEvent.allCases.forEach { attempt.complete($0, error: nil) }
    attempt.complete(AppEvent.onboardingLoaded, error: nil)
}

@main
private struct ConfigurationAttemptExecutableTests {
    static func main() {
        finishesWhenAllEventsComplete()
        firesAttAndConfigLoadedOnce()
        finishesByTimer()
        cancelledAttemptIgnoresCompletionsAndTimer()
        timerOfCancelledAttemptDoesNotFinishNewOne()
        alreadyCompletedEventsAreKept()
        cancellingInAttributionCallbackStopsFinish()
        completionInsideAttributionCallbackFinishesOnce()
        detectsNetworkErrors()
        print("ConfigurationAttemptExecutableTests: PASS")
    }

    static func finishesWhenAllEventsComplete() {
        let attempt = makeAttempt()
        var results = [ConfigurationResult]()
        var attributionCalls = 0
        attempt.onAttributionFinished = { attributionCalls += 1 }
        attempt.onFinished = { results.append($0) }
        completeAll(attempt)
        require(results.count == 1, "All events must finish the attempt exactly once")
        require(attributionCalls == 1, "Attribution must finish before the attempt finishes")
        require(attempt.isFinished && attempt.isAttributionFinished, "Flags must follow the callbacks")
    }

    static func firesAttAndConfigLoadedOnce() {
        let attempt = makeAttempt()
        var calls = 0
        attempt.onAttAndConfigLoaded = { calls += 1 }
        attempt.complete(InternalConfigurationEvent.attConcentGiven, error: nil)
        require(calls == 0, "ATT alone must not report the remote config as loaded")
        attempt.complete(InternalConfigurationEvent.remoteConfigLoaded, error: nil)
        attempt.complete(InternalConfigurationEvent.remoteConfigLoaded, error: nil)
        require(calls == 1, "ATT + remote config must be reported exactly once")
    }

    static func finishesByTimer() {
        let attempt = makeAttempt(timeout: 1)
        var results = [ConfigurationResult]()
        var attributionCalls = 0
        attempt.onAttributionFinished = { attributionCalls += 1 }
        attempt.onFinished = {
            require(Thread.isMainThread, "The timer must finish the attempt on main")
            results.append($0)
        }
        attempt.startTimer()
        attempt.startTimer()
        spinMain(for: 0.5)
        require(results.isEmpty, "The timer must not fire early")
        spinMain(for: 1.0)
        require(results == [.requiredFailed], "The timer must finish once; the required app event is missing")
        require(attributionCalls == 1, "The timer must finish attribution first")
    }

    static func cancelledAttemptIgnoresCompletionsAndTimer() {
        let attempt = makeAttempt(timeout: 1)
        var finished = false
        attempt.onFinished = { _ in finished = true }
        attempt.startTimer()
        attempt.cancel()
        completeAll(attempt)
        spinMain(for: 1.5)
        require(finished == false, "A cancelled attempt must ignore completions and its timer")
        require(attempt.statusForAnalytics["remoteConfigLoaded"] == "not finished",
                "A cancelled attempt must not record late completions")
    }

    static func timerOfCancelledAttemptDoesNotFinishNewOne() {
        let first = makeAttempt(timeout: 1)
        first.startTimer()
        spinMain(for: 0.5)
        first.cancel()
        let second = makeAttempt(timeout: 2)
        var secondFinished = false
        second.onFinished = { _ in secondFinished = true }
        second.startTimer()
        spinMain(for: 1.0)
        require(secondFinished == false, "The first attempt's timer must not finish the second attempt")
        spinMain(for: 2.0)
        require(secondFinished, "The second attempt must finish by its own timer")
    }

    static func alreadyCompletedEventsAreKept() {
        let attError = NSError(domain: "coreintegrations.att.timeout", code: 6456)
        let attempt = makeAttempt(alreadyCompleted: [
            (event: InternalConfigurationEvent.attConcentGiven, error: attError),
            (event: AppEvent.onboardingLoaded, error: nil)
        ])
        let status = attempt.statusForAnalytics
        require(status["attConcentGiven"] == "error: 6456", "A carried ATT answer must keep its error")
        require(status["onboardingLoaded"] == "finished", "A carried app event must count as finished")
        var results = [ConfigurationResult]()
        attempt.onFinished = { results.append($0) }
        [InternalConfigurationEvent.remoteConfigLoaded, .appsflyerWeb2AppHandled,
         .attributionServerHandled, .remoteConfigUpdated].forEach { attempt.complete($0, error: nil) }
        require(results == [.completed], "Carried events plus the rest must complete the attempt")
    }

    static func cancellingInAttributionCallbackStopsFinish() {
        let attempt = makeAttempt()
        var finished = false
        attempt.onAttributionFinished = { attempt.cancel() }
        attempt.onFinished = { _ in finished = true }
        completeAll(attempt)
        require(finished == false, "A cancel inside the attribution callback must stop the finish")
    }

    static func completionInsideAttributionCallbackFinishesOnce() {
        let attempt = makeAttempt()
        var finishes = 0
        attempt.onAttributionFinished = {
            attempt.complete(InternalConfigurationEvent.remoteConfigUpdated, error: nil)
        }
        attempt.onFinished = { _ in finishes += 1 }
        attempt.complete(AppEvent.onboardingLoaded, error: nil)
        [InternalConfigurationEvent.attConcentGiven, .remoteConfigLoaded,
         .appsflyerWeb2AppHandled].forEach { attempt.complete($0, error: nil) }
        require(finishes == 0, "Attribution is not finished yet")
        // The last attribution event fires the callback, whose completion is the last missing event.
        attempt.complete(InternalConfigurationEvent.attributionServerHandled, error: nil)
        require(finishes == 1, "A completion inside the attribution callback must finish the attempt exactly once")
    }

    static func detectsNetworkErrors() {
        let attempt = makeAttempt()
        attempt.complete(InternalConfigurationEvent.remoteConfigLoaded, error: networkError)
        require(attempt.completedWithNetworkErrors == false, "One failed service is not a network failure")
        attempt.complete(InternalConfigurationEvent.attributionServerHandled, error: networkError)
        require(attempt.completedWithNetworkErrors, "Both services failing is a network failure")
    }
}
