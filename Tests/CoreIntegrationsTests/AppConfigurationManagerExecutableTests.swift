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
        let backgroundGeneration = backgroundConfiguration.generation
        var backgroundFinishCount = 0
        var backgroundFinishRanOnMain = false
        backgroundConfiguration.signForConfigurationEnd { _, _ in
            backgroundFinishCount += 1
            backgroundFinishRanOnMain = Thread.isMainThread
        }
        let backgroundCompletionReturned = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            order.forEach {
                backgroundConfiguration.handleCompleted(event: $0, error: nil, generation: backgroundGeneration)
            }
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

        // Completions queued on main before a reset belong to the reset generation and are dropped.
        let queuedConfiguration = makeConfiguration()
        let queuedGeneration = queuedConfiguration.generation
        let queuedCompletionsReturned = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            order.forEach {
                queuedConfiguration.handleCompleted(event: $0, error: nil, generation: queuedGeneration)
            }
            queuedCompletionsReturned.signal()
        }
        // Main is blocked until every completion is queued, so all of them land after the reset.
        queuedCompletionsReturned.wait()
        queuedConfiguration.reset()
        var queuedNextGenerationFinishCount = 0
        queuedConfiguration.signForConfigurationEnd { _, _ in
            queuedNextGenerationFinishCount += 1
        }
        drainMainQueue()
        require(queuedNextGenerationFinishCount == 0,
                "Completions queued before a reset must not finish the next generation")
        require(queuedConfiguration.generation == 1,
                "The reset must start the next generation")
        require(order.allSatisfy { queuedConfiguration.statusForAnalytics[$0.key] == "not finished" },
                "Completions queued before a reset must not mark the next generation's events")

        // A late response to a request of the reset generation is dropped; one of the current
        // generation is applied.
        let lateConfiguration = makeConfiguration()
        let staleGeneration = lateConfiguration.generation
        lateConfiguration.reset()
        let lateEvent = InternalConfigurationEvent.remoteConfigLoaded
        lateConfiguration.handleCompleted(event: lateEvent, error: nil, generation: staleGeneration)
        require(lateConfiguration.statusForAnalytics[lateEvent.key] == "not finished",
                "A late response of the reset generation must be dropped")
        lateConfiguration.handleCompleted(event: lateEvent, error: nil, generation: lateConfiguration.generation)
        require(lateConfiguration.statusForAnalytics[lateEvent.key] == "finished",
                "A response of the current generation must be applied")

        // `perform(in:)` runs the block on main only while its generation is current.
        let performConfiguration = makeConfiguration()
        let performStaleGeneration = performConfiguration.generation
        performConfiguration.reset()
        let performCurrentGeneration = performConfiguration.generation
        var staleBlockRuns = 0
        var currentBlockRuns = 0
        var currentBlockRanOnMain = false
        let performsQueued = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            performConfiguration.perform(in: performStaleGeneration) {
                staleBlockRuns += 1
            }
            performConfiguration.perform(in: performCurrentGeneration) {
                currentBlockRuns += 1
                currentBlockRanOnMain = Thread.isMainThread
            }
            performsQueued.signal()
        }
        performsQueued.wait()
        drainMainQueue()
        require(staleBlockRuns == 0,
                "A block of a reset generation must never run")
        require(currentBlockRuns == 1 && currentBlockRanOnMain,
                "A block of the current generation must run on main exactly once")

        // A timer started before a reset must not finish the next generation; the next
        // generation's own timer does.
        let resetTimerConfiguration = makeConfiguration(timeout: 1)
        resetTimerConfiguration.startTimoutTimer()
        resetTimerConfiguration.reset()
        var resetTimerFinishes = [Int]()
        resetTimerConfiguration.signForConfigurationEnd { _, generation in
            resetTimerFinishes.append(generation)
        }
        // Past the 1-second timeout of the reset generation's timer.
        let staleTimerDeadline = Date(timeIntervalSinceNow: 2)
        while Date() < staleTimerDeadline {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }
        require(resetTimerFinishes.isEmpty,
                "A timer of a reset generation must not finish the next one")

        resetTimerConfiguration.startTimoutTimer()
        let resetTimerDeadline = Date(timeIntervalSinceNow: 3)
        while resetTimerFinishes.isEmpty, Date() < resetTimerDeadline {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }
        require(resetTimerFinishes == [1],
                "The next generation's timer must finish it exactly once")

        print("AppConfigurationManagerExecutableTests: PASS")
    }
}
