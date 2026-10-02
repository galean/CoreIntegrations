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

        var configurationPolicy = AppsFlyerConfigurationOutcomePolicy()
        require(configurationPolicy.shouldAcceptConversionResult,
                "GCD must be able to complete configuration before a start failure")
        configurationPolicy.recordSessionStartFailure()
        require(configurationPolicy.shouldAcceptConversionResult == false,
                "GCD must not overwrite session-start error 1002")
        configurationPolicy.reset()
        require(configurationPolicy.shouldAcceptConversionResult,
                "A new configuration generation must accept GCD again")

        var orderingPolicy = AppsFlyerStartOrderingPolicy<String>()
        require(orderingPolicy.receiveConversion("organic") == "organic",
                "Conversion outside an in-flight start must be delivered immediately")
        orderingPolicy.beginStart()
        require(orderingPolicy.receiveConversion("cached") == nil,
                "Conversion must wait until the start result is known")
        require(orderingPolicy.finishStart() == "cached",
                "The buffered conversion must be released after start completion")
        require(orderingPolicy.finishStart() == nil,
                "Buffered conversion must be released only once")

        var overlappingOrderingPolicy = AppsFlyerStartOrderingPolicy<String>()
        overlappingOrderingPolicy.beginStart()
        require(overlappingOrderingPolicy.receiveConversion("overlap") == nil,
                "Conversion must be buffered while the first start is outstanding")
        overlappingOrderingPolicy.beginStart()
        require(overlappingOrderingPolicy.finishStart() == nil,
                "The first completion must not release GCD while another start is outstanding")
        require(overlappingOrderingPolicy.finishStart() == "overlap",
                "The last overlapping completion must release the buffered GCD exactly once")

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
