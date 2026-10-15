import AppTrackingTransparency
import Foundation

extension CoreManager {
    struct ATTAnswer {
        let status: ATTrackingManager.AuthorizationStatus
        let error: Error?
    }

    enum ATTSource {
        case currentStatus, callback, poll, timeout, external
    }

    /*
     The answer is taken once per process from whichever comes first: the system callback, a poll of
     the status (the callback sometimes never arrives), the 5 s fallback, or `handleATTPermission(_:)`.
     */
    func requestATT() {
        assert(Thread.isMainThread, "requestATT is main-thread only")
        let status = ATTrackingManager.trackingAuthorizationStatus
        if status != .notDetermined {
            sendATTProperty(answer: status == .authorized)
            // Answered while our request is in flight (the activation can beat the system callback).
            resolveATT(status, source: isATTRequestInFlight ? .poll : .currentStatus)
            return
        }

        guard attAnswer == nil, isATTRequestInFlight == false else {
            return
        }
        isATTRequestInFlight = true
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            MainQueueExecutor.perform {
                self?.resolveATT(status, source: .callback)
            }
        }
        pollATT(until: Date().addingTimeInterval(5))
    }

    func resolveATT(_ status: ATTrackingManager.AuthorizationStatus, source: ATTSource) {
        assert(Thread.isMainThread, "resolveATT is main-thread only")
        guard attAnswer == nil else {
            return
        }
        let isUnanswered = status == .notDetermined
        guard isUnanswered == false || source == .timeout || source == .external else {
            return
        }

        let error: Error? = isUnanswered ? NSError(domain: "coreintegrations.att.timeout", code: 6456) : nil
        let answer = ATTAnswer(status: status, error: error)
        attAnswer = answer
        isATTRequestInFlight = false
        if source != .currentStatus {
            sendAttEvent(answer: status == .authorized)
        }

        // An answer given before `configureAll` (an early `handleATTPermission`) is applied by it.
        guard configurationAttempt != nil else {
            return
        }
        applyATTAnswer(answer)
    }

    func applyATTAnswer(_ answer: ATTAnswer) {
        // Only the first launch meets the system network prompt; later launches take the plain path.
        if AppEnvironment.isChina && configuration?.appSettings.isFirstLaunch == true {
            delayConfigurationForChina(answer)
        } else {
            startConfigurationAttempt()
            configureATTConsumers(answer)
        }
    }

    /// Every attempt that has the ATT answer starts here: the first one, the China restart and the retry.
    func startConfigurationAttempt() {
        assert(Thread.isMainThread, "startConfigurationAttempt is main-thread only")
        guard let attAnswer, let attempt = configurationAttempt else {
            assertionFailure("A configuration attempt needs the ATT answer")
            return
        }
        sendConfigurationStarted(status: [:])
        attempt.startTimer()
        recordProcessEvent(InternalConfigurationEvent.attConcentGiven, error: attAnswer.error)
    }

    private func pollATT(until deadline: Date) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.attAnswer == nil else {
                return
            }
            let status = ATTrackingManager.trackingAuthorizationStatus
            if status != .notDetermined {
                self.resolveATT(status, source: .poll)
            } else if Date() >= deadline {
                self.resolveATT(status, source: .timeout)
            } else {
                self.pollATT(until: deadline)
            }
        }
    }

    // The system asks for network access on the first launch in China, so the first requests fail;
    // the configuration restarts once the network is there, or after 6 s.
    private func delayConfigurationForChina(_ answer: ATTAnswer) {
        sendConfigurationDelayed(status: [:])

        var isRestarted = false
        let restart = { [weak self] in
            guard isRestarted == false else {
                return
            }
            isRestarted = true
            self?.restartConfigurationAfterATT(answer)
        }
        networkMonitor.monitorInternetChanges { isConnected in
            if isConnected {
                restart()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: restart)
    }

    private func restartConfigurationAfterATT(_ answer: ATTAnswer) {
        restartConfiguration()
        configureATTConsumers(answer)
    }

    private func configureATTConsumers(_ answer: ATTAnswer) {
        facebookManager?.configureATT(isAuthorized: answer.status == .authorized)
        appsflyerManager?.handleATTResolved()
    }
}
