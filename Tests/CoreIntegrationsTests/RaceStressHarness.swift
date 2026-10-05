// Stress harness for AppConfigurationManager: the real class, models and MainQueueExecutor, driven
// the way CoreManager drives them, with no mocks of the class under test. Background completions
// enter through `handleCompleted(event:error:generation:)`, tagged with the generation captured on main.
//
// mode "reset":       the completions arrive on a global queue (attribution server / remote config
//                     thread); the last one's attribution callback runs CoreManager's no-internet branch
//                     synchronously inside checkConfiguration() on main, which calls reset() and
//                     reconfigure() re-signs. Each iteration requires that the interrupted generation
//                     never finishes, that a late completion of it is dropped, and that the next
//                     generation finishes exactly once on its own completions.
// mode "two-threads": two completions arrive on two global-queue threads at once, no reset at all
//                     (attribution server completion vs remote config completion). Each iteration
//                     requires exactly one finish.
//
// Build and run from the package root (default 20 000 iterations; 300 under TSan):
//   SRC=(Sources/CoreIntegrations/CoreManager/MainQueueExecutor.swift \
//        Sources/CoreIntegrations/ConfigurationManager/AppConfigurationManager.swift \
//        Sources/CoreIntegrations/ConfigurationManager/Models/ConfigurationResult.swift \
//        Sources/CoreIntegrations/ConfigurationManager/Models/CoreConfigurationModel.swift \
//        Sources/CoreIntegrations/ConfigurationManager/Models/InternalConfigurationEvent.swift \
//        Sources/CoreIntegrations/ConfigurationManager/Protocols/ConfigurationEvent.swift)
//   xcrun swiftc -swift-version 5 -target arm64-apple-macosx14.0 -O "${SRC[@]}" \
//       Tests/CoreIntegrationsTests/RaceStressHarness.swift -o /tmp/stress
//   /tmp/stress reset 20000 && /tmp/stress two-threads 20000
//   xcrun swiftc -swift-version 5 -target arm64-apple-macosx14.0 -Onone -g -sanitize=thread "${SRC[@]}" \
//       Tests/CoreIntegrationsTests/RaceStressHarness.swift -o /tmp/stress-tsan
//   TSAN_OPTIONS="halt_on_error=0" /tmp/stress-tsan reset 300
//   TSAN_OPTIONS="halt_on_error=0" /tmp/stress-tsan two-threads 300
//
// The original race reproduced on c7e7596: 5/5 crashes per mode (see ClickUp 869fc51e4).
import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

private final class MiniCoreManager {
    var finishes = 0
    func sign() {
        let cm = AppConfigurationManager.shared!
        cm.signForConfigurationEnd { [weak self] _, _ in
            MainQueueExecutor.perform { self?.finishes += 1 }
        }
        cm.signForAttAndConfigLoaded { }
    }
}

private func fresh() -> (AppConfigurationManager, Int) {
    let m = AppConfigurationManager(
        model: CoreConfigurationModel(allConfigurationEvents: InternalConfigurationEvent.allCases, isFirstStart: true),
        timeout: 6)
    AppConfigurationManager.shared = m
    return (m, m.generation)
}

// attribution-relevant events last, so attribution and configuration finish on the same completion
private let order: [InternalConfigurationEvent] = [.remoteConfigUpdated, .attConcentGiven, .remoteConfigLoaded,
                                                   .appsflyerWeb2AppHandled, .attributionServerHandled]

@main
private struct RaceStressHarness {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        let mode = args.first ?? "reset"
        let n = Int(args.dropFirst().first ?? "20000")!

        // Pumps main until everything already queued on main has run.
        func drainMain() {
            var sentinel = false
            DispatchQueue.main.async { sentinel = true }
            while !sentinel { RunLoop.main.run(mode: .default, before: .distantPast) }
        }

        // Pumps main until `done` is signalled, then drains it.
        func waitAndDrainMain(_ done: DispatchSemaphore) {
            while done.wait(timeout: .now()) != .success { RunLoop.main.run(mode: .default, before: .distantPast) }
            drainMain()
        }

        for i in 0..<n {
            let (m, g) = fresh()
            let core = MiniCoreManager()
            core.sign()
            let done = DispatchSemaphore(value: 0)
            switch mode {
            case "reset":
                // The re-signed callbacks of the next generation count their finishes separately.
                let nextCore = MiniCoreManager()
                var didReset = false
                m.signForAttributionFinished {
                    // Same hop as CoreManager.handleAttributionFinish, so the reset runs synchronously
                    // inside checkConfiguration() on main.
                    MainQueueExecutor.perform { m.reset(); nextCore.sign(); didReset = true }
                }
                DispatchQueue.global().async {
                    order.forEach { m.handleCompleted(event: $0, error: nil, generation: g) }
                    done.signal()
                }
                // The last completion's hop is queued before `done`, so the reset has run once main is drained.
                waitAndDrainMain(done)
                require(didReset,
                        "The last completion of the interrupted generation must reset it")
                require(core.finishes == 0,
                        "The interrupted generation must not finish: the reset dropped its callbacks")

                // A late completion of the interrupted generation is dropped.
                let lateDone = DispatchSemaphore(value: 0)
                DispatchQueue.global().async {
                    m.handleCompleted(event: InternalConfigurationEvent.remoteConfigLoaded, error: nil, generation: g)
                    lateDone.signal()
                }
                waitAndDrainMain(lateDone)
                require(m.statusForAnalytics[InternalConfigurationEvent.remoteConfigLoaded.key] == "not finished",
                        "A late completion of the interrupted generation must be dropped")
                require(nextCore.finishes == 0,
                        "Completions of the reset generation must not finish the next one")
                require(order.filter { $0 != .attConcentGiven }.allSatisfy { m.statusForAnalytics[$0.key] == "not finished" },
                        "Completions of the reset generation must not mark the next one's events")
                // The ATT answer is given once per process, so `reset()` keeps it by design.
                require(m.statusForAnalytics[InternalConfigurationEvent.attConcentGiven.key] == "finished",
                        "The ATT answer must survive the reset")

                // The next generation must still finish on its own completions.
                let nextGeneration = m.generation
                let nextDone = DispatchSemaphore(value: 0)
                DispatchQueue.global().async {
                    order.forEach { m.handleCompleted(event: $0, error: nil, generation: nextGeneration) }
                    nextDone.signal()
                }
                waitAndDrainMain(nextDone)
                require(nextCore.finishes == 1,
                        "The next generation must finish exactly once on its own completions")
            case "two-threads":
                let group = DispatchGroup()
                for part in [Array(order[0..<2]), Array(order[2..<5])] {
                    group.enter()
                    DispatchQueue.global().async {
                        part.forEach { m.handleCompleted(event: $0, error: nil, generation: g) }
                        group.leave()
                    }
                }
                group.notify(queue: .global()) { done.signal() }
                waitAndDrainMain(done)
                require(core.finishes == 1,
                        "Two concurrent completion streams must finish the configuration exactly once")
            default:
                fatalError("unknown mode")
            }
            if i % 5000 == 4999 { FileHandle.standardError.write("iter \(i + 1)\n".data(using: .utf8)!) }
        }
        print("RaceStressHarness \(mode): \(n) iterations: PASS")
    }
}
