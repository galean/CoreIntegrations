import AppTrackingTransparency
import Foundation

extension CoreManager {
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
        networkMonitor.monitorInternetChanges { [weak self] isEnabled in
            guard isEnabled, isReconfigured == false else {
                return
            }
            isReconfigured = true
            self?.reconfigureAfterATT(status, error: error)
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + 6) { [weak self] in
            guard isReconfigured == false else {
                return
            }
            isReconfigured = true
            self?.reconfigureAfterATT(status, error: error)
        }
    }

    private func finishConfigurationAfterATT(_ status: ATTrackingManager.AuthorizationStatus,
                                             error: Error?) {
        sendConfigurationStarted(status: [:])
        configurationAttempt?.startTimer()
        recordProcessEvent(InternalConfigurationEvent.attConcentGiven, error: error)
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

        sendConfigurationStarted(status: [:])
        reconfigure()
        configurationAttempt?.startTimer()
        recordProcessEvent(InternalConfigurationEvent.attConcentGiven, error: error)
        facebookManager?.configureATT(isAuthorized: status == .authorized)
        appsflyerManager?.handleATTResolved()
        appsflyerManager?.startAppsflyer()
    }
}
