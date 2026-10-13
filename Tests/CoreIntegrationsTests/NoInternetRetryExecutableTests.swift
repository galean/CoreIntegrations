private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

@main
private struct NoInternetRetryExecutableTests {
    static func main() {
        var retry = NoInternetRetry()
        require(retry.shouldDeliverNoInternet(isChina: false, isFirstLaunch: true, completedWithNetworkErrors: true) == false,
                "Outside China a failure finishes normally")
        require(retry.shouldDeliverNoInternet(isChina: true, isFirstLaunch: false, completedWithNetworkErrors: true) == false,
                "Later launches finish normally")
        require(retry.shouldDeliverNoInternet(isChina: true, isFirstLaunch: true, completedWithNetworkErrors: false) == false,
                "One failed service is not a no-internet result")
        require(retry.claimRetry() == false, "There is nothing to retry before .noInternet")

        require(retry.shouldDeliverNoInternet(isChina: true, isFirstLaunch: true, completedWithNetworkErrors: true),
                "China, first launch, both services failed: .noInternet")
        require(retry.claimRetry(), "The first trigger retries")
        require(retry.claimRetry() == false, "The second trigger finds nothing to do")
        require(retry.shouldDeliverNoInternet(isChina: true, isFirstLaunch: true, completedWithNetworkErrors: true) == false,
                "A failed retry finishes as .finished, never a second .noInternet")

        var optedOut = NoInternetRetry()
        optedOut.optOut()
        require(optedOut.isOptedOut, "The hook before any .noInternet opts out")
        require(optedOut.shouldDeliverNoInternet(isChina: true, isFirstLaunch: true, completedWithNetworkErrors: true) == false,
                "An opted-out app gets .finished")
        require(optedOut.claimRetry() == false, "An opted-out app gets no retry")

        var late = NoInternetRetry()
        _ = late.shouldDeliverNoInternet(isChina: true, isFirstLaunch: true, completedWithNetworkErrors: true)
        late.optOut()
        require(late.isOptedOut == false, "The hook after .noInternet changes nothing")
        require(late.claimRetry(), "The retry still happens after a late hook")

        print("NoInternetRetryExecutableTests: PASS")
    }
}
