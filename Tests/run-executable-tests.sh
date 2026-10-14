#!/bin/bash
# Builds and runs the executable tests: framework files without third-party SDKs, compiled
# with swiftc for macOS. Usage: Tests/run-executable-tests.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

CORE="$ROOT/Sources/CoreIntegrations"
TESTS="$ROOT/Tests/CoreIntegrationsTests"

run() {
    local name="$1"
    shift
    xcrun swiftc -parse-as-library -swift-version 5 "$@" -o "$OUT/$name"
    "$OUT/$name"
}

CONFIGURATION="$CORE/ConfigurationManager"

run ConfigurationAttempt \
    "$CONFIGURATION/ConfigurationAttempt.swift" \
    "$CONFIGURATION/Models/CoreConfigurationModel.swift" \
    "$CONFIGURATION/Models/InternalConfigurationEvent.swift" \
    "$CONFIGURATION/Models/ConfigurationResult.swift" \
    "$CONFIGURATION/Protocols/ConfigurationEvent.swift" \
    "$TESTS/ConfigurationAttemptExecutableTests.swift"

run AppsFlyerStartGate \
    "$ROOT/Sources/AppsflyerIntegration/AppsFlyerStartGate.swift" \
    "$TESTS/AppsFlyerStartGateExecutableTests.swift"

run AppsFlyerSessionStatus \
    "$ROOT/Sources/AppsflyerIntegration/AppsFlyerSessionStatus.swift" \
    "$TESTS/AppsFlyerSessionStatusExecutableTests.swift"

run NoInternetRetry \
    "$CORE/CoreManager/NoInternetRetry.swift" \
    "$TESTS/NoInternetRetryExecutableTests.swift"
