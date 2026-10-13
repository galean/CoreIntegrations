import Foundation

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

    /// A new attempt with the remote config reloaded. The caller decides whether it starts (timer, ATT event).
    func reconfigure() {
        let attempt = beginConfigurationAttempt()
        remoteConfigManager?.updateRemoteConfig([:]) { [weak self] in
            self?.remoteConfigManager?.configure(self?.configuration?.remoteConfigDataSource.allConfigs ?? []) { [weak self] in
                let error = self?.remoteConfigManager?.remoteError
                MainQueueExecutor.perform {
                    attempt.complete(InternalConfigurationEvent.remoteConfigLoaded, error: error)
                }
            }
        }
    }

    func analyticsStatus(of attempt: ConfigurationAttempt) -> [String: String] {
        var status = attempt.statusForAnalytics
        status["appsflyerSession"] = (appsflyerManager?.appsflyerSession ?? .notStarted).rawValue
        return status
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
