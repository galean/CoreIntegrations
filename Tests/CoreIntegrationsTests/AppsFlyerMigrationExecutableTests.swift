import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

@main
private struct AppsFlyerMigrationExecutableTests {
    static func main() {
        var sessionStartPolicy = AppsFlyerSessionStartPolicy()
        require(sessionStartPolicy.claimStart() == false,
                "AppsFlyer must not start before the readiness listener fires")
        sessionStartPolicy.sessionBecameReady()
        require(sessionStartPolicy.claimStart(),
                "The first gate convergence in a ready cycle must start AppsFlyer")
        require(sessionStartPolicy.claimStart() == false,
                "Repeated gate updates must not start AppsFlyer twice in the same ready cycle")
        sessionStartPolicy.sessionBecameReady()
        require(sessionStartPolicy.claimStart() == false,
                "A listener re-fire in the same foreground cycle must not open a second start")
        sessionStartPolicy.sessionBecameUnavailable()
        require(sessionStartPolicy.claimStart() == false,
                "A background transition must close stale readiness")
        sessionStartPolicy.sessionBecameReady()
        require(sessionStartPolicy.claimStart(),
                "The next foreground cycle must allow the next AppsFlyer session")
        sessionStartPolicy.sessionBecameReady()
        require(sessionStartPolicy.claimStart() == false,
                "The next foreground cycle must allow exactly one start")

        require(AppsFlyerSessionState.started.rawValue == "started"
                    && AppsFlyerSessionState.starting.rawValue == "starting"
                    && AppsFlyerSessionState.failed.rawValue == "failed"
                    && AppsFlyerSessionState.notStarted.rawValue == "not started",
                "Session states must keep their analytics values")

        var sessionTally = AppsFlyerSessionTally()
        let startDate = Date()
        require(sessionTally.state == .notStarted,
                "No start call must report not started")
        let firstAttempt = sessionTally.beginStart(at: startDate)
        require(firstAttempt.number == 1 && firstAttempt.secondsSincePreviousAttempt == nil,
                "The first attempt must be number 1 without a previous interval")
        require(sessionTally.state == .starting,
                "An unfinished call must report starting")
        sessionTally.finishStart(succeeded: false)
        require(sessionTally.state == .failed,
                "A failed call with nothing in flight must report failed")
        let secondAttempt = sessionTally.beginStart(at: startDate.addingTimeInterval(2.5))
        require(secondAttempt.number == 2 && secondAttempt.secondsSincePreviousAttempt == 2.5,
                "The next attempt must carry its number and the time since the previous call")
        require(sessionTally.state == .starting,
                "Starting must win over failed")
        sessionTally.finishStart(succeeded: true)
        require(sessionTally.state == .started,
                "A successful call must report started")
        _ = sessionTally.beginStart(at: startDate.addingTimeInterval(10))
        require(sessionTally.state == .started,
                "Started must win over starting")
        sessionTally.finishStart(succeeded: false)
        require(sessionTally.state == .started,
                "Started must win over failed")

        var overlappingTally = AppsFlyerSessionTally()
        let overlappingNumbers = [overlappingTally.beginStart(at: startDate).number,
                                  overlappingTally.beginStart(at: startDate).number,
                                  overlappingTally.beginStart(at: startDate).number]
        require(overlappingNumbers == [1, 2, 3],
                "Overlapping attempts must not share a number")

        func isRateLimited(_ error: NSError) -> Bool {
            AppsFlyerStartAttempt(number: 1, secondsSincePreviousAttempt: nil, error: error).isRateLimited
        }
        require(isRateLimited(NSError(domain: "com.appsflyer.sdk.event", code: 10)),
                "A start inside minTimeBetweenSessions must be classified as rate limited")
        require(isRateLimited(NSError(domain: "com.appsflyer.sdk.event", code: 11)) == false,
                "Another event error code must stay an error")
        require(isRateLimited(NSError(domain: "com.appsflyer.sdk.network", code: 10)) == false,
                "Code 10 from another domain must stay an error")

        // A GCD result alone - nothing else has happened before it - completes the AppsFlyer
        // step to finished through a real AppConfigurationManager.
        let allEvents: [any ConfigurationEvent] = InternalConfigurationEvent.allCases
        AppConfigurationManager.shared = AppConfigurationManager(
            model: CoreConfigurationModel(allConfigurationEvents: allEvents, isFirstStart: true)
        )
        InternalConfigurationEvent.appsflyerWeb2AppHandled.markAsCompleted()
        require(AppConfigurationManager.shared?.statusForAnalytics["appsflyerWeb2AppHandled"] == "finished",
                "A GCD result alone must complete the AppsFlyer step to finished")

        let timedOutConfiguration = AppConfigurationManager(
            model: CoreConfigurationModel(allConfigurationEvents: allEvents, isFirstStart: true),
            timeout: 1
        )
        AppConfigurationManager.shared = timedOutConfiguration
        var configurationEndCount = 0
        timedOutConfiguration.signForConfigurationEnd { _ in
            DispatchQueue.main.async {
                configurationEndCount += 1
            }
        }
        timedOutConfiguration.startTimoutTimer()

        let timeoutDeadline = Date(timeIntervalSinceNow: 3)
        while configurationEndCount == 0, Date() < timeoutDeadline {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }
        require(configurationEndCount == 1,
                "The configuration timer must finish configuration without GCD")
        require(timedOutConfiguration.statusForAnalytics["appsflyerWeb2AppHandled"] == "not finished",
                "The timer must leave the AppsFlyer step not finished")

        InternalConfigurationEvent.appsflyerWeb2AppHandled.markAsCompleted()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        require(configurationEndCount == 1,
                "A late GCD must not finish configuration a second time")
        require(timedOutConfiguration.statusForAnalytics["appsflyerWeb2AppHandled"] == "finished",
                "A late GCD still updates the step status, without a second configuration finish")

        // A finish callback carries the generation it was signed in; the hop to main delivers
        // the finish only while that generation is still current.
        let generationConfiguration = AppConfigurationManager(
            model: CoreConfigurationModel(allConfigurationEvents: allEvents, isFirstStart: true)
        )
        require(generationConfiguration.generation == 0,
                "A new configuration must start at generation 0")
        generationConfiguration.reset()
        require(generationConfiguration.generation == 1,
                "A reset must start the next generation")

        func finishAllEvents(of configuration: AppConfigurationManager) {
            allEvents.forEach { configuration.handleCompleted(event: $0, error: nil) }
        }

        var staleGeneration: Int?
        let signedGeneration = generationConfiguration.generation
        generationConfiguration.signForConfigurationEnd { _ in
            staleGeneration = signedGeneration
        }
        finishAllEvents(of: generationConfiguration)
        // The no-internet flow resets the generation before the hop to main lands.
        generationConfiguration.reset()
        require(staleGeneration != nil && staleGeneration != generationConfiguration.generation,
                "A finish whose generation was reset before the hop must be dropped")

        var deliveredGeneration: Int?
        let nextSignedGeneration = generationConfiguration.generation
        generationConfiguration.signForConfigurationEnd { _ in
            deliveredGeneration = nextSignedGeneration
        }
        finishAllEvents(of: generationConfiguration)
        require(deliveredGeneration == generationConfiguration.generation,
                "A finish whose generation is still current must be delivered")
        require(staleGeneration != generationConfiguration.generation,
                "A stale finish must stay dropped after the next generation has finished")

        var fastPathGenerations = [Int]()
        let fastPathSignedGeneration = generationConfiguration.generation
        generationConfiguration.signForConfigurationEnd { _ in
            fastPathGenerations.append(fastPathSignedGeneration)
        }
        require(fastPathGenerations == [generationConfiguration.generation],
                "Signing on a finished configuration must deliver the finish once, immediately")

        // A callback signed before a reset never fires after it: the reset drops the signed
        // callbacks, so a sign-time generation cannot be confused with the next one.
        var droppedBySignCount = 0
        generationConfiguration.reset()
        generationConfiguration.signForConfigurationEnd { _ in droppedBySignCount += 1 }
        generationConfiguration.reset()
        finishAllEvents(of: generationConfiguration)
        require(droppedBySignCount == 0,
                "A reset must drop the callbacks signed in the previous generation")

        var synchronousMainExecution = false
        MainQueueExecutor.perform {
            synchronousMainExecution = true
        }
        require(synchronousMainExecution,
                "Work submitted from main must execute synchronously")

        let backgroundHandoffFinished = DispatchSemaphore(value: 0)
        var backgroundHandoffRanOnMain = false
        DispatchQueue.global().async {
            MainQueueExecutor.perform {
                backgroundHandoffRanOnMain = Thread.isMainThread
                backgroundHandoffFinished.signal()
            }
        }

        let handoffDeadline = Date(timeIntervalSinceNow: 2)
        while backgroundHandoffFinished.wait(timeout: .now()) != .success,
              Date() < handoffDeadline {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }
        require(backgroundHandoffRanOnMain,
                "Work submitted from a background queue must be handed off to main")

        print("AppsFlyerMigrationExecutableTests: PASS")
    }
}
