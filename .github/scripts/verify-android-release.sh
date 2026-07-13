#!/usr/bin/env bash
# Verify release APK is signed and print certificate fingerprints for release notes.
set -euo pipefail

APK_PATH="${1:-build/app/outputs/flutter-apk/app-release.apk}"
REQUIRE_RELEASE_SIGNING="${REQUIRE_RELEASE_SIGNING:-false}"

if [[ ! -f "$APK_PATH" ]]; then
  echo "APK not found: $APK_PATH" >&2
  exit 1
fi

if ! command -v apksigner >/dev/null 2>&1; then
  SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
  if [[ -z "$SDK_ROOT" && -f android/local.properties ]]; then
    SDK_ROOT=$(grep -E '^sdk\.dir=' android/local.properties | cut -d= -f2- | tr -d '\r' | sed 's#\\:#/#g' | sed 's#\\(/[^\\]\)#\1#g')
  fi
  if [[ -n "$SDK_ROOT" ]]; then
    APKSIGNER=$(find "$SDK_ROOT/build-tools" -name apksigner -type f 2>/dev/null | sort -V | tail -n 1 || true)
    if [[ -n "${APKSIGNER:-}" ]]; then
      export PATH="$(dirname "$APKSIGNER"):$PATH"
    fi
  fi
fi

APKSIGNER_BIN=""
if command -v apksigner >/dev/null 2>&1; then
  APKSIGNER_BIN="apksigner"
elif [[ -n "${APKSIGNER:-}" && -x "$APKSIGNER" ]]; then
  APKSIGNER_BIN="$APKSIGNER"
fi

if [[ -z "$APKSIGNER_BIN" ]]; then
  echo "::error::apksigner not found. Install Android SDK build-tools in CI." >&2
  exit 1
fi

"$APKSIGNER_BIN" verify --verbose "$APK_PATH" >/dev/null

CERTS=$("$APKSIGNER_BIN" verify --print-certs "$APK_PATH")
echo "$CERTS"

if [[ "$REQUIRE_RELEASE_SIGNING" == "true" ]] && echo "$CERTS" | grep -q "CN=Android Debug"; then
  echo "::error::Release APK is debug-signed. Configure ANDROID_KEYSTORE_BASE64 and related secrets." >&2
  exit 1
fi

SHA256=$(echo "$CERTS" | awk -F': ' '/SHA-256 digest/ {print $2; exit}')
if [[ -n "$SHA256" && -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "APK_SHA256_FINGERPRINT=$SHA256" >> "$GITHUB_OUTPUT"
fi

echo "Release APK verification passed."
