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

run ATTResolutionPolicy \
    "$CORE/CoreManager/ATTResolutionPolicy.swift" \
    "$CORE/CoreManager/ATTResolutionCoordinator.swift" \
    "$CORE/CoreManager/MainQueueExecutor.swift" \
    "$TESTS/ATTResolutionPolicyExecutableTests.swift"

CONFIGURATION="$CORE/ConfigurationManager"

run ConfigurationAttempt \
    "$CONFIGURATION/ConfigurationAttempt.swift" \
    "$CONFIGURATION/Models/CoreConfigurationModel.swift" \
    "$CONFIGURATION/Models/InternalConfigurationEvent.swift" \
    "$CONFIGURATION/Models/ConfigurationResult.swift" \
    "$CONFIGURATION/Protocols/ConfigurationEvent.swift" \
    "$TESTS/ConfigurationAttemptExecutableTests.swift"
