private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

private func openGate() -> AppsFlyerStartGate {
    var gate = AppsFlyerStartGate()
    gate.isATTResolved = true
    gate.isSessionReady = true
    return gate
}

@main
private struct AppsFlyerStartGateExecutableTests {
    static func main() {
        var gate = AppsFlyerStartGate()
        require(gate.claimStart(hasCustomerUserID: true) == false, "A closed gate must not start")

        gate = openGate()
        gate.isATTResolved = false
        require(gate.claimStart(hasCustomerUserID: true) == false, "The session must wait for ATT")

        gate = openGate()
        require(gate.claimStart(hasCustomerUserID: false) == false, "The session must wait for the customer user ID")

        gate = openGate()
        gate.isSessionReady = false
        require(gate.claimStart(hasCustomerUserID: true) == false, "The session must wait for the SDK readiness")

        gate = openGate()
        require(gate.claimStart(hasCustomerUserID: true), "An open gate must start")
        require(gate.claimStart(hasCustomerUserID: true) == false, "One start per foreground cycle")
        gate.isSessionReady = true
        require(gate.claimStart(hasCustomerUserID: true) == false,
                "Readiness firing again in the same cycle must not start again")

        gate.enteredBackground()
        require(gate.claimStart(hasCustomerUserID: true) == false, "The background must close the readiness")
        gate.isSessionReady = true
        require(gate.claimStart(hasCustomerUserID: true), "The next foreground cycle must start once")

        print("AppsFlyerStartGateExecutableTests: PASS")
    }
}
