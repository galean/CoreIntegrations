import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

private let rateLimited = NSError(domain: "com.appsflyer.sdk.event", code: 10)
private let offline = NSError(domain: NSURLErrorDomain, code: -1009)

@main
private struct AppsFlyerSessionStatusExecutableTests {
    static func main() {
        var status = AppsFlyerSessionStatus()
        require(status.value == "not started", "Nothing started yet")

        status.startBegan()
        require(status.value == "starting", "A start is in flight")
        status.startBegan()
        status.startFinished(error: rateLimited)
        require(status.value == "starting", "A rejected later start must not hide the first one in flight")
        status.startFinished(error: nil)
        require(status.value == "started", "The first start succeeded")
        status.startBegan()
        status.startFinished(error: offline)
        require(status.value == "started", "A session that went through stays started")

        var failed = AppsFlyerSessionStatus()
        failed.startBegan()
        failed.startFinished(error: offline)
        require(failed.value == "error: \(NSURLErrorDomain) -1009", "With nothing in flight the last error is reported")

        print("AppsFlyerSessionStatusExecutableTests: PASS")
    }
}
