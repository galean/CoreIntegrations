import AppTrackingTransparency
import Foundation

extension CoreManager {
    // Only the error is replayed on a retry (a nil error is still an answer); the status is
    // consumed once, by the handlers that receive it.
    struct ATTAnswer {
        let error: Error?
    }

    func makeATTResolutionCoordinator() -> ATTResolutionCoordinator<ATTrackingManager.AuthorizationStatus> {
        ATTResolutionCoordinator(
            notDetermined: ATTrackingManager.AuthorizationStatus.notDetermined,
            statusProvider: {
                ATTrackingManager.trackingAuthorizationStatus
            },
            requestAuthorization: { completion in
                ATTrackingManager.requestTrackingAuthorization(completionHandler: completion)
            },
            schedule: ATTResolutionCoordinator<ATTrackingManager.AuthorizationStatus>.scheduleOnMain,
            onTerminalStatusObserved: { [weak self] status in
                self?.sendATTProperty(answer: status == .authorized)
            },
            onResolved: { [weak self] resolution in
                self?.handleATTResolution(resolution)
            }
        )
    }

    func requestATT() {
        attResolutionCoordinator.startDefaultFlow()
    }

    private func handleATTResolution(_ resolution: ATTResolution<ATTrackingManager.AuthorizationStatus>) {
        let status = resolution.status
        if resolution.source != .currentStatus {
            sendAttEvent(answer: status == .authorized)
        }
        let error: Error? = status == .notDetermined && resolution.source == .timeout
            ? NSError(domain: "coreintegrations.att.timeout", code: 6456)
            : nil
        handleATTAnswered(status, error: error)
    }

    private func handleATTAnswered(_ status: ATTrackingManager.AuthorizationStatus,
                                   error: Error? = nil) {
        if AppEnvironment.isChina {
            handleChinaATTAnswer(status, error: error)
        } else {
            finishConfigurationAfterATT(status, error: error)
        }
    }

    private func handleChinaATTAnswer(_ status: ATTrackingManager.AuthorizationStatus,
                                      error: Error?) {
        sendConfigurationDelayed(status: [:])

        var isReconfigured = false
        // Both triggers decide on main, one after the other, so the first attempt is started
        // exactly once; the monitor delivers on main, so the hop is a no-op kept as a safety net.
        networkMonitor.monitorInternetChanges { [weak self] isEnabled in
            MainQueueExecutor.perform {
                guard isEnabled, isReconfigured == false else {
                    return
                }
                isReconfigured = true
                self?.reconfigureAfterATT(status, error: error)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            guard isReconfigured == false else {
                return
            }
            isReconfigured = true
            self?.reconfigureAfterATT(status, error: error)
        }
    }

    /// Every configuration attempt, the first one and each retry, starts here.
    func startConfigurationAttempt() {
        assert(Thread.isMainThread, "startConfigurationAttempt is main-thread only")
        guard let attAnswer else {
            assertionFailure("A configuration attempt needs the ATT answer")
            return
        }
        sendConfigurationStarted(status: [:])
        AppConfigurationManager.shared?.startTimoutTimer()
        InternalConfigurationEvent.attConcentGiven.markAsCompleted(error: attAnswer.error)
    }

    private func finishConfigurationAfterATT(_ status: ATTrackingManager.AuthorizationStatus,
                                             error: Error?) {
        attAnswer = ATTAnswer(error: error)
        startConfigurationAttempt()
        facebookManager?.configureATT(isAuthorized: status == .authorized)
        appsflyerManager?.handleATTResolved()
    }

    private func reconfigureAfterATT(_ status: ATTrackingManager.AuthorizationStatus,
                                     error: Error?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.reconfigureAfterATT(status, error: error)
            }
            return
        }

        attAnswer = ATTAnswer(error: error)
        reconfigure()
        facebookManager?.configureATT(isAuthorized: status == .authorized)
        appsflyerManager?.handleATTResolved()
        appsflyerManager?.startAppsflyer()
    }
}
