#!/usr/bin/env bash
# Publishes Android APK/AAB to a GitHub Release (used by CI).
set -euo pipefail

APK_PATH="${APK_PATH:-build/app/outputs/flutter-apk/app-release.apk}"
AAB_PATH="${AAB_PATH:-build/app/outputs/bundle/release/app-release.aab}"
TAG_NAME="${TAG_NAME:?TAG_NAME is required}"
RELEASE_NAME="${RELEASE_NAME:-$TAG_NAME}"
RELEASE_BODY="${RELEASE_BODY:-Automated Duo Mobile release.}"

if [[ ! -f "$APK_PATH" ]]; then
  echo "APK not found: $APK_PATH" >&2
  exit 1
fi

FILES=("$APK_PATH")
if [[ -f "$AAB_PATH" ]]; then
  FILES+=("$AAB_PATH")
fi

ARGS=(
  --tag "$TAG_NAME"
  --title "$RELEASE_NAME"
  --notes "$RELEASE_BODY"
  --latest
)

for file in "${FILES[@]}"; do
  ARGS+=(--attach "$file")
done

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  export GH_TOKEN="$GITHUB_TOKEN"
fi

if command -v gh >/dev/null 2>&1; then
  gh release create "${ARGS[@]}"
  echo "Published release $TAG_NAME"
  exit 0
fi

echo "gh CLI not available; use softprops/action-gh-release in workflow." >&2
exit 1
