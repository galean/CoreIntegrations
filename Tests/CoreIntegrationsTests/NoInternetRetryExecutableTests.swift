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
        require(retry.claimRetry(for: .network) == false, "There is nothing to retry before .noInternet")

        require(retry.shouldDeliverNoInternet(isChina: true, isFirstLaunch: true, completedWithNetworkErrors: true),
                "China, first launch, both services failed: .noInternet")
        require(retry.claimRetry(for: .network), "The first trigger retries")
        require(retry.claimRetry(for: .network) == false, "The second trigger finds nothing to do")
        require(retry.shouldDeliverNoInternet(isChina: true, isFirstLaunch: true, completedWithNetworkErrors: true) == false,
                "A failed retry finishes as .finished, never a second .noInternet")

        var optedOut = NoInternetRetry()
        optedOut.optOut()
        require(optedOut.isOptedOut, "The hook before any .noInternet opts out")
        require(optedOut.shouldDeliverNoInternet(isChina: true, isFirstLaunch: true, completedWithNetworkErrors: true) == false,
                "An opted-out app gets .finished")
        require(optedOut.claimRetry(for: .network) == false, "An opted-out app gets no retry")

        var late = NoInternetRetry()
        _ = late.shouldDeliverNoInternet(isChina: true, isFirstLaunch: true, completedWithNetworkErrors: true)
        late.optOut()
        require(late.isOptedOut == false, "The hook after .noInternet changes nothing")
        require(late.claimRetry(for: .network), "The retry still happens after a late hook")

        var dialog = NoInternetRetry()
        dialog.enteredBackground()
        _ = dialog.shouldDeliverNoInternet(isChina: true, isFirstLaunch: true, completedWithNetworkErrors: true)
        require(dialog.claimRetry(for: .activation) == false,
                "An activation without a trip to the background (a system dialog) does not retry")
        dialog.enteredBackground()
        require(dialog.claimRetry(for: .activation), "Returning from the background retries")
        require(dialog.claimRetry(for: .network) == false, "Only one retry")

        var beforeFailure = NoInternetRetry()
        beforeFailure.enteredBackground()
        _ = beforeFailure.shouldDeliverNoInternet(isChina: true, isFirstLaunch: true, completedWithNetworkErrors: true)
        require(beforeFailure.claimRetry(for: .activation) == false,
                "A background trip before .noInternet does not count")
        require(beforeFailure.claimRetry(for: .network), "The network trigger needs no background trip")

        print("NoInternetRetryExecutableTests: PASS")
    }
}
