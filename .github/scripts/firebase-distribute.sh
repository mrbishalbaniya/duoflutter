#!/usr/bin/env bash
# Optional Firebase App Distribution upload.
set -euo pipefail

APK_PATH="${1:-build/app/outputs/flutter-apk/app-release.apk}"
AAB_PATH="${2:-build/app/outputs/bundle/release/app-release.aab}"

if [[ -z "${FIREBASE_APP_ID:-}" || -z "${FIREBASE_TOKEN:-}" ]]; then
  echo "::warning::FIREBASE_APP_ID or FIREBASE_TOKEN not set — skipping App Distribution."
  exit 0
fi

npm install -g firebase-tools

if [[ -f "$APK_PATH" ]]; then
  firebase appdistribution:distribute "$APK_PATH" \
    --app "$FIREBASE_APP_ID" \
    --token "$FIREBASE_TOKEN" \
    --groups "${FIREBASE_DISTRIBUTION_GROUPS:-testers}" \
    --release-notes "Build ${GITHUB_SHA:0:7} from ${GITHUB_REF_NAME}"
fi

if [[ -f "$AAB_PATH" ]]; then
  firebase appdistribution:distribute "$AAB_PATH" \
    --app "$FIREBASE_APP_ID" \
    --token "$FIREBASE_TOKEN" \
    --groups "${FIREBASE_DISTRIBUTION_GROUPS:-testers}" \
    --release-notes "Build ${GITHUB_SHA:0:7} from ${GITHUB_REF_NAME}"
fi

echo "Firebase App Distribution upload complete."
