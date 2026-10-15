import Foundation

/// One configuration attempt. Main thread only.
///
/// A cancelled attempt ignores completions and its timer and never calls back, so a late response
/// or a timer of an earlier attempt cannot finish a newer one. `alreadyCompleted` is recorded without
/// evaluation; the callbacks run from `complete(_:error:)` and the timer.
final class ConfigurationAttempt {
    var onAttAndConfigLoaded: (() -> Void)?
    var onAttributionFinished: (() -> Void)?
    var onFinished: ((ConfigurationResult) -> Void)?

    private(set) var isCancelled = false
    private(set) var isAttributionFinished = false
    private(set) var isFinished = false

    private var model: CoreConfigurationModel
    private let timeout: Int
    private var isTimerStarted = false
    private var isTimedOut = false
    private var isAttAndConfigLoaded = false

    init(events: [any ConfigurationEvent],
         isFirstStart: Bool,
         timeout: Int,
         alreadyCompleted: [(event: any ConfigurationEvent, error: Error?)] = []) {
        model = CoreConfigurationModel(allConfigurationEvents: events, isFirstStart: isFirstStart)
        self.timeout = timeout
        alreadyCompleted.forEach { record($0.event, error: $0.error) }
    }

    /// Both network services failed: the remote config and the attribution server.
    var completedWithNetworkErrors: Bool {
        model.checkCompletedWithErrors()
    }

    var statusForAnalytics: [String: String] {
        model.statusDescription
    }

    func complete(_ event: any ConfigurationEvent, error: Error?) {
        assertMainThread()
        guard isCancelled == false else {
            return
        }
        record(event, error: error)
        evaluate()
    }

    func startTimer() {
        assertMainThread()
        guard isCancelled == false, isFinished == false, isTimerStarted == false else {
            return
        }
        isTimerStarted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(timeout)) { [weak self] in
            guard let self, self.isCancelled == false, self.isFinished == false else {
                return
            }
            self.isTimedOut = true
            self.evaluate()
        }
    }

    func cancel() {
        assertMainThread()
        isCancelled = true
    }

    private func record(_ event: any ConfigurationEvent, error: Error?) {
        if model.completedEvents.contains(where: { $0.key == event.key }) == false {
            model.completedEvents.append(event)
        }
        if let error {
            model.completionErrors[event.key] = error
        } else {
            model.completionErrors.removeValue(forKey: event.key)
        }
    }

    // Each callback may cancel the attempt (the no-internet flow), so the state is re-checked after it.
    private func evaluate() {
        if isAttAndConfigLoaded == false, model.checkAttAndConfigFinished() {
            isAttAndConfigLoaded = true
            onAttAndConfigLoaded?()
            guard isCancelled == false else { return }
        }

        let shouldFinish = isTimedOut || model.checkAllEventsFinished()
        if isAttributionFinished == false, shouldFinish || model.checkAttributionFinished() {
            isAttributionFinished = true
            onAttributionFinished?()
            guard isCancelled == false else { return }
        }

        guard shouldFinish, isFinished == false else {
            return
        }
        isFinished = true
        onFinished?(model.checkRequiredEventsFinished() ? .completed : .requiredFailed)
    }

    private func assertMainThread() {
        assert(Thread.isMainThread, "ConfigurationAttempt is main-thread only")
    }
}
