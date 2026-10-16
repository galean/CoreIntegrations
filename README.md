# CoreIntegrations
Framework version - 3.1.1

## No internet on the first launch in China

On the first launch, iOS in China asks for network access per app, so the first requests often fail.

- After the ATT answer the framework waits for the network (up to 6 s) and restarts the configuration.
- If the remote config and the attribution server both fail, `coreConfigurationFinished(result: .noInternet)` is delivered. The app may show a "no internet" alert.
- The framework then retries once, when the app returns from the background (e.g. from Settings) or the network appears while it is active, and delivers `coreConfigurationFinished(result: .finished)` within the configuration timeout, with or without network.
- If the app shows no alert and the user neither leaves the app nor gets network, the retry waits; do not block the UI on the second callback.
- `handleNoInternetAlertWasShown()` called before any `.noInternet` opts out: failures finish as `.finished` without a retry.
- Later launches and other regions never get `.noInternet`.
