# CoreIntegrations 3.1.0 smoke test

Real device, clean install for every first-launch scenario. Watch Xcode console (`[START]`, `[ATT]` from AppsFlyer debug) and Amplitude.

## ATT

1. Answer within 5 s → one `att_permission`; `framework_attribution_started`; AppsFlyer `[START]` after the answer, first session has IDFA when allowed.
2. Do not touch the prompt → after ~5 s `att_permission` = false, `framework_finished` with `attConcentGiven = error: 6456`; `[START]` still appears.
3. App with its own ATT flow (`useDefaultATTRequest = false`, calls `handleATTPermission`) → same events as 1.

## AppsFlyer

4. Cold start → exactly one `[START]` per foreground cycle; Control Center / system alerts do not add one; background → foreground adds one.
5. `framework_finished.appsflyerSession` is `started` on a normal launch.

## China (device region CN)

6. First launch, network access denied in the system prompt → `framework_start_delayed`, `.noInternet` delivered. Go to Settings, keep network off, return → `.finished` within ~6 s, one `framework_finished`.
7. First launch offline, then enable network while the app stays in the foreground → retry starts, one `framework_finished` and one `framework_attribution`. A retry in the same foreground cycle starts no new AppsFlyer session; that is expected.
7a. First launch offline, `.noInternet` delivered while the system network-access prompt is shown; dismiss the prompt without leaving the app → no retry yet; then go to Settings and come back → `.finished` within ~6 s.
8. Second launch → one `framework_finished`, no `framework_start_delayed`, no `.noInternet`.
9. App that calls `handleNoInternetAlertWasShown()` in `didFinishLaunching` → first launch offline ends with `.finished`, no `.noInternet`, no retry.

## Regions other than CN

10. First launch offline → `.finished` by the timer, never `.noInternet`.
