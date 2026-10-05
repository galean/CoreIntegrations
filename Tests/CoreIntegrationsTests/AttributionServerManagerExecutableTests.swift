// AttributionServerIntegration uses UIKit (`UIDevice` in AttributionUserDefaultsWorker and
// AttributionDataWorker), so it cannot be built for macOS like the other executable tests. This one is
// built for Mac Catalyst against the real, unchanged module sources, with LoggingIntegration as a
// separate static module because the sources import it.
//
// Build and run from the package root (-Onone and -g as in the other executable tests):
//   OUT=/tmp/asm-tests-build; mkdir -p "$OUT"
//   SDK=$(xcrun --show-sdk-path --sdk macosx)
//   CATALYST=(-target arm64-apple-ios15.0-macabi -sdk "$SDK" \
//             -Fsystem "$SDK/System/iOSSupport/System/Library/Frameworks" \
//             -I "$SDK/System/iOSSupport/usr/include" -L "$SDK/System/iOSSupport/usr/lib")
//   xcrun swiftc -swift-version 5 "${CATALYST[@]}" -parse-as-library -emit-library -static -emit-module \
//       -module-name LoggingIntegration Sources/LoggingIntegration/DebugLogger.swift \
//       -emit-module-path "$OUT/LoggingIntegration.swiftmodule" -o "$OUT/libLoggingIntegration.a"
//   xcrun swiftc -swift-version 5 "${CATALYST[@]}" -Onone -g -I "$OUT" -L "$OUT" -lLoggingIntegration \
//       $(find Sources/AttributionServerIntegration -name '*.swift') \
//       Tests/CoreIntegrationsTests/AttributionServerManagerExecutableTests.swift -o "$OUT/asm-tests"
//   "$OUT/asm-tests"            # all cases; "$OUT/asm-tests" d runs only case (d)
//
// UserDefaults: AttributionUserDefaultsWorker always uses `UserDefaults.standard`. A command-line
// executable has no bundle identifier, so its standard domain is the executable's name
// (~/Library/Preferences/asm-tests.plist): no app's data is touched. The worker's keys are still
// cleaned before and after every case.
//
// What each case catches (saved-install branch of `syncOnAppStart`):
//   (a), (b) - the completion is not called at all (as before this branch completed), called twice, or
//              called synchronously, before `syncOnAppStart` returns.
//   (c)      - the completion is called on the path without a saved server user ID too, e.g. moved
//              above the guard. It passes against the code that never completed this branch.
//   (d)      - `installError` is not cleared, so an error already set is delivered with the saved result.
//   (e)      - an `installError` written after `syncOnAppStart` returned is delivered with the saved
//              result: also catches clearing it before the hop to main instead of right before delivery.
import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

// The keys AttributionUserDefaultsWorker writes.
private let workerKeys = ["ANALYTICS_DATA_TO_SAVE", "ANALYTICS_USER_ID", "ANALYTICS_PURCHASE_DATA",
                          "ANALYTICS_EXTERNAL_AUTH_DATA", "ANALYTICS_GENERATED_TOKEN", "ANALYTICS_INSTALL_RESULT",
                          "STORED_UUID_KEY", "ANALYTICS_APP_TRANSACTION_SENT", "ANALYTICS_FCM_TOKEN"]

private func cleanWorkerKeys() {
    workerKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
}

// Everything already enqueued on main has run once this lands.
private func drainMainQueue() {
    var sentinelLanded = false
    DispatchQueue.main.async {
        sentinelLanded = true
    }
    while sentinelLanded == false {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
    }
}

// Gives a second, wrong completion time to land.
private func pumpMainQueue(for seconds: TimeInterval) {
    let end = Date(timeIntervalSinceNow: seconds)
    while Date() < end {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
    }
}

private func makeManager() -> AttributionServerManager {
    let manager = AttributionServerManager()
    manager.authorizationToken = "token"
    return manager
}

private let savedResult = AttributionManagerResult(userUUID: "server-user-id", idfv: "idfv-1",
                                                   asaAttribution: ["campaignName": "campaign-1"], isIPAT: true)

private func saveRegisteredInstall(withResult: Bool) {
    let worker = AttributionUserDefaultsWorker()
    worker.saveServerUserID("server-user-id")
    if withResult {
        worker.saveInstallResult(savedResult)
    }
}

private func noInternetError() -> NSError {
    NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
}

private struct Delivery {
    var count = 0
    var result: AttributionManagerResult?
    var ranOnMain = false
    var installErrorAtDelivery: Error?
}

// (a) Saved server user ID and saved install result.
private func savedIDWithResult() {
    saveRegisteredInstall(withResult: true)
    let manager = makeManager()
    var delivery = Delivery()
    manager.syncOnAppStart { result in
        delivery.count += 1
        delivery.result = result
        delivery.ranOnMain = Thread.isMainThread
    }
    require(delivery.count == 0, "(a) The completion must not run before syncOnAppStart returns")
    drainMainQueue()
    pumpMainQueue(for: 0.3)
    require(delivery.count == 1, "(a) The completion must run exactly once, ran \(delivery.count) times")
    require(delivery.ranOnMain, "(a) The completion must run on main")
    require(delivery.result?.userUUID == savedResult.userUUID
                && delivery.result?.idfv == savedResult.idfv
                && delivery.result?.asaAttribution == savedResult.asaAttribution
                && delivery.result?.isIPAT == savedResult.isIPAT,
            "(a) The completion must carry the saved install result")
}

// (b) Saved server user ID without an install result (legacy data).
private func savedIDWithoutResult() {
    saveRegisteredInstall(withResult: false)
    let manager = makeManager()
    var delivery = Delivery()
    delivery.result = savedResult
    manager.syncOnAppStart { result in
        delivery.count += 1
        delivery.result = result
    }
    require(delivery.count == 0, "(b) The completion must not run before syncOnAppStart returns")
    drainMainQueue()
    pumpMainQueue(for: 0.3)
    require(delivery.count == 1, "(b) The completion must run exactly once, ran \(delivery.count) times")
    require(delivery.result == nil, "(b) The completion must carry nil without a saved install result")
}

// (c) No saved server user ID and no server worker: the completion belongs to the install request,
// which cannot be sent, so it never runs. Saved install data keeps the production branch from collecting
// it live: `collectInstallData()` reads `identifierForVendor`, which a Catalyst command-line executable
// may not have (the `uuid` getter then traps on an empty string). The branch still starts an unawaited
// Task, which only reads the saved data and finds no server worker.
private func noSavedID() {
    AttributionUserDefaultsWorker().saveInstallData(AttributionInstallRequestModel(
        userId: "test-user-id", idfa: nil, idfv: nil, sdkVersion: "test", osVersion: "test", appVersion: "test",
        limitAdTracking: false, storeCountry: nil, appsflyerId: nil, iosATT: nil, environment: nil, fb: nil, sa: nil,
        externalAuthorization: nil))
    let manager = makeManager()
    var delivery = Delivery()
    manager.syncOnAppStart { _ in
        delivery.count += 1
    }
    drainMainQueue()
    pumpMainQueue(for: 1)
    require(delivery.count == 0, "(c) Without a saved server user ID this branch must not complete, ran \(delivery.count) times")
}

// (d) An install error is already set when syncOnAppStart is called.
private func errorSetBeforeTheCall() {
    saveRegisteredInstall(withResult: true)
    let manager = makeManager()
    manager.installError = noInternetError()
    var delivery = Delivery()
    manager.syncOnAppStart { result in
        delivery.count += 1
        delivery.result = result
        delivery.installErrorAtDelivery = manager.installError
    }
    drainMainQueue()
    require(delivery.count == 1, "(d) The completion must run exactly once, ran \(delivery.count) times")
    require(delivery.result != nil, "(d) The completion must carry the saved install result")
    require(delivery.installErrorAtDelivery == nil, "(d) A registered install must be delivered without installError")
}

// (e) Another install request writes an error after syncOnAppStart returned, before the delivery.
private func errorSetAfterTheCall() {
    saveRegisteredInstall(withResult: true)
    let manager = makeManager()
    var delivery = Delivery()
    manager.syncOnAppStart { result in
        delivery.count += 1
        delivery.result = result
        delivery.installErrorAtDelivery = manager.installError
    }
    // The completion is deferred to main, so it has not run yet.
    manager.installError = noInternetError()
    drainMainQueue()
    require(delivery.count == 1, "(e) The completion must run exactly once, ran \(delivery.count) times")
    require(delivery.result != nil, "(e) The completion must carry the saved install result")
    require(delivery.installErrorAtDelivery == nil,
            "(e) An error written after the call must not be delivered with the registered install")
}

@main
private struct AttributionServerManagerExecutableTests {
    static func main() {
        let cases: [(name: String, run: () -> Void)] = [
            ("a", savedIDWithResult), ("b", savedIDWithoutResult), ("c", noSavedID),
            ("d", errorSetBeforeTheCall), ("e", errorSetAfterTheCall)
        ]
        let selected = Set(CommandLine.arguments.dropFirst())
        let toRun = cases.filter { selected.isEmpty || selected.contains($0.name) }
        require(toRun.isEmpty == false, "Unknown case: \(selected.sorted())")

        for testCase in toRun {
            cleanWorkerKeys()
            testCase.run()
            cleanWorkerKeys()
        }
        print("AttributionServerManagerExecutableTests: PASS (\(toRun.map(\.name).joined(separator: ", ")))")
    }
}
