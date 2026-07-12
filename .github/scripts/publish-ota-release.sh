#!/usr/bin/env bash
# Upload release APK to DuoBackend OTA API and emit version.json for clients.
set -euo pipefail

APK_PATH="${1:-build/app/outputs/flutter-apk/app-release.apk}"
API_BASE_URL="${API_BASE_URL:-https://duobackend.onrender.com/api}"
OTA_PUBLISH_TOKEN="${OTA_PUBLISH_TOKEN:-}"
RELEASE_NOTES_FILE="${RELEASE_NOTES_FILE:-RELEASE_NOTES.md}"
VERSION_JSON_PATH="${VERSION_JSON_PATH:-version.json}"

if [[ -z "$OTA_PUBLISH_TOKEN" ]]; then
  echo "OTA_PUBLISH_TOKEN is not set; skipping OTA publish." >&2
  exit 0
fi

if [[ ! -f "$APK_PATH" ]]; then
  echo "APK not found: $APK_PATH" >&2
  exit 1
fi

FULL_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
VERSION_NAME="${FULL_VERSION%%+*}"
BUILD_NUMBER="${FULL_VERSION##*+}"
if [[ "$BUILD_NUMBER" == "$FULL_VERSION" ]]; then
  BUILD_NUMBER="${GITHUB_RUN_NUMBER:-1}"
fi

NOTES_JSON='[]'
if [[ -f "$RELEASE_NOTES_FILE" ]]; then
  NOTES_JSON=$(python3 -c "import json, pathlib; text=pathlib.Path('${RELEASE_NOTES_FILE}').read_text(encoding='utf-8'); lines=[l.strip()[2:] for l in text.splitlines() if l.strip().startswith('- ')]; print(json.dumps(lines[:20]))")
fi

GITHUB_RELEASE_URL=""
if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
  GITHUB_RELEASE_URL="https://github.com/${GITHUB_REPOSITORY}/releases/latest/download/app-release.apk"
fi

CURL_ARGS=(
  -sS
  -X POST
  "${API_BASE_URL%/}/app/version/publish/"
  -H "X-OTA-Token: ${OTA_PUBLISH_TOKEN}"
  -F "version=${VERSION_NAME}"
  -F "build_number=${BUILD_NUMBER}"
  -F "platform=android"
  -F "channel=stable"
  -F "activate=true"
  -F "soft_update=true"
  -F "force_update=false"
  -F "release_notes=${NOTES_JSON}"
  -F "apk_file=@${APK_PATH};type=application/vnd.android.package-archive"
)

if [[ -n "$GITHUB_RELEASE_URL" ]]; then
  CURL_ARGS+=(-F "apk_url=${GITHUB_RELEASE_URL}")
fi

RESPONSE=$(curl "${CURL_ARGS[@]}")
echo "$RESPONSE" > "$VERSION_JSON_PATH"
echo "Wrote ${VERSION_JSON_PATH}"
echo "OTA publish complete for ${VERSION_NAME}+${BUILD_NUMBER}"
