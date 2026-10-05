// Build and run from the package root (-Onone keeps the main-thread `assert`s active):
//   SRC=(Sources/CoreIntegrations/CoreManager/MainQueueExecutor.swift \
//        Sources/CoreIntegrations/ConfigurationManager/AppConfigurationManager.swift \
//        Sources/CoreIntegrations/ConfigurationManager/Models/ConfigurationResult.swift \
//        Sources/CoreIntegrations/ConfigurationManager/Models/CoreConfigurationModel.swift \
//        Sources/CoreIntegrations/ConfigurationManager/Models/InternalConfigurationEvent.swift \
//        Sources/CoreIntegrations/ConfigurationManager/Protocols/ConfigurationEvent.swift)
//   xcrun swiftc -swift-version 5 -target arm64-apple-macosx14.0 -Onone -g "${SRC[@]}" \
//       Tests/CoreIntegrationsTests/AppConfigurationManagerExecutableTests.swift -o /tmp/acm-tests && /tmp/acm-tests
// Add -sanitize=thread to the same command to check it under TSan.
import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

@main
private struct AppConfigurationManagerExecutableTests {
    static func main() {
        let allEvents: [any ConfigurationEvent] = InternalConfigurationEvent.allCases
        // Attribution-relevant events last, so attribution and configuration finish on the same completion.
        let order: [InternalConfigurationEvent] = [.remoteConfigUpdated, .attConcentGiven, .remoteConfigLoaded,
                                                   .appsflyerWeb2AppHandled, .attributionServerHandled]

        func makeConfiguration(timeout: Int = 6) -> AppConfigurationManager {
            AppConfigurationManager(
                model: CoreConfigurationModel(allConfigurationEvents: allEvents, isFirstStart: true),
                timeout: timeout
            )
        }

        // Everything already enqueued on main has run once this lands.
        func drainMainQueue() {
            var sentinelLanded = false
            DispatchQueue.main.async {
                sentinelLanded = true
            }
            while sentinelLanded == false {
                RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
            }
        }

        // A completion delivered on a background queue is applied on main.
        let backgroundConfiguration = makeConfiguration()
        var backgroundFinishCount = 0
        var backgroundFinishRanOnMain = false
        backgroundConfiguration.signForConfigurationEnd { _, _ in
            backgroundFinishCount += 1
            backgroundFinishRanOnMain = Thread.isMainThread
        }
        let backgroundCompletionReturned = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            order.forEach { backgroundConfiguration.handleCompleted(event: $0, error: nil) }
            backgroundCompletionReturned.signal()
        }
        // Main is blocked here, so a completion applied on the background thread would already
        // have finished the configuration.
        backgroundCompletionReturned.wait()
        require(backgroundFinishCount == 0,
                "A background completion must not be applied before main runs")
        drainMainQueue()
        require(backgroundFinishCount == 1,
                "A background completion must finish the configuration exactly once")
        require(backgroundFinishRanOnMain,
                "A background completion must finish the configuration on main")
        require(order.allSatisfy { backgroundConfiguration.statusForAnalytics[$0.key] == "finished" },
                "A background completion must mark its event finished")

        // The configuration timer fires on main.
        let timedOutConfiguration = makeConfiguration(timeout: 1)
        var timeoutFinishCount = 0
        var timeoutFinishRanOnMain = false
        timedOutConfiguration.signForConfigurationEnd { _, _ in
            timeoutFinishCount += 1
            timeoutFinishRanOnMain = Thread.isMainThread
        }
        timedOutConfiguration.startTimoutTimer()
        let timeoutDeadline = Date(timeIntervalSinceNow: 3)
        while timeoutFinishCount == 0, Date() < timeoutDeadline {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }
        require(timeoutFinishCount == 1,
                "The configuration timer must finish configuration exactly once")
        require(timeoutFinishRanOnMain,
                "The configuration timer must finish configuration on main")

        // The no-internet flow resets inside the attribution callback and re-signs the next
        // generation; that generation must not finish with the reset one's result.
        let resetConfiguration = makeConfiguration()
        var nextGenerationFinishes = [Int]()
        resetConfiguration.signForAttributionFinished {
            resetConfiguration.reset()
            resetConfiguration.signForConfigurationEnd { _, generation in
                nextGenerationFinishes.append(generation)
            }
        }
        order.forEach { resetConfiguration.handleCompleted(event: $0, error: nil) }
        require(nextGenerationFinishes.isEmpty,
                "A reset inside the attribution callback must not finish the next generation")
        require(resetConfiguration.configurationFinishHandled == false,
                "A reset inside the attribution callback must leave the next generation unfinished")
        require(resetConfiguration.generation == 1,
                "A reset inside the attribution callback must start the next generation")

        order.forEach { resetConfiguration.handleCompleted(event: $0, error: nil) }
        require(nextGenerationFinishes == [1],
                "The next generation must finish once on its own events")

        print("AppConfigurationManagerExecutableTests: PASS")
    }
}
