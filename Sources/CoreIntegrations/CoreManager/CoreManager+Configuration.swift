import Foundation
import UIKit

extension CoreManager {
    /// Cancels the current attempt and starts a new one that already carries the process facts.
    @discardableResult
    func beginConfigurationAttempt() -> ConfigurationAttempt {
        assert(Thread.isMainThread, "beginConfigurationAttempt is main-thread only")
        configurationAttempt?.cancel()

        let attempt = ConfigurationAttempt(events: configurationEvents,
                                           isFirstStart: configuration?.appSettings.isFirstLaunch ?? false,
                                           timeout: configuration?.configurationTimeout ?? 6,
                                           alreadyCompleted: processCompletedEvents)
        attempt.onAttAndConfigLoaded = { [weak self, unowned attempt] in
            self?.handleAttributionInstall(for: attempt)
        }
        attempt.onAttributionFinished = { [weak self] in
            self?.handleAttributionFinish(isUpdated: false)
        }
        attempt.onFinished = { [weak self, unowned attempt] _ in
            self?.handleConfigurationFinish(of: attempt)
        }
        configurationAttempt = attempt
        return attempt
    }

    /// A fact given once per process: kept for every later attempt and applied to the current one.
    func recordProcessEvent(_ event: any ConfigurationEvent, error: Error?) {
        assert(Thread.isMainThread, "recordProcessEvent is main-thread only")
        processCompletedEvents.removeAll { $0.event.key == event.key }
        processCompletedEvents.append((event: event, error: error))
        configurationAttempt?.complete(event, error: error)
    }

    /// Starts a new attempt with the remote config reloaded: the China restart and the retry after `.noInternet`.
    func restartConfiguration() {
        let attempt = beginConfigurationAttempt()
        remoteConfigManager?.updateRemoteConfig([:]) { [weak self] in
            self?.remoteConfigManager?.configure(self?.configuration?.remoteConfigDataSource.allConfigs ?? []) { [weak self] in
                let error = self?.remoteConfigManager?.remoteError
                MainQueueExecutor.perform {
                    attempt.complete(InternalConfigurationEvent.remoteConfigLoaded, error: error)
                }
            }
        }
        startConfigurationAttempt()
    }

    func analyticsStatus(of attempt: ConfigurationAttempt) -> [String: String] {
        var status = attempt.statusForAnalytics
        status["appsflyerSession"] = appsflyerManager?.sessionStatus ?? "not started"
        return status
    }
}

extension CoreManager {
    /// The one retry after `.noInternet`: the app returning from the background (with or without
    /// network) or the network appearing while it is active, whichever comes first. It always ends in `.finished`.
    func retryAfterNoInternet(trigger: NoInternetRetry.Trigger) {
        assert(Thread.isMainThread, "retryAfterNoInternet is main-thread only")
        if trigger == .network, UIApplication.shared.applicationState != .active {
            return
        }
        guard noInternetRetry.claimRetry(for: trigger) else {
            return
        }
        restartConfiguration()
    }
}

public extension ConfigurationEvent {
    /// Any thread. Applied on main to the current configuration attempt and kept for later attempts:
    /// mark an app-defined event once per process.
    func markAsCompleted() {
        MainQueueExecutor.perform {
            CoreManager.internalShared.recordProcessEvent(self, error: nil)
        }
    }
}
