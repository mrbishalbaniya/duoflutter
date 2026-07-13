#!/usr/bin/env bash
# Decode Android keystore from GitHub secrets for signed release builds.
set -euo pipefail

if [[ -z "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  if [[ "${REQUIRE_RELEASE_SIGNING:-false}" == "true" ]]; then
    echo "::error::ANDROID_KEYSTORE_BASE64 is required for signed release builds." >&2
    echo "Create a keystore (see documentation/ANDROID_INSTALL.md) and add GitHub secrets:" >&2
    echo "  ANDROID_KEYSTORE_BASE64, KEYSTORE_PASSWORD, KEY_PASSWORD, KEY_ALIAS" >&2
    exit 1
  fi
  echo "::warning::ANDROID_KEYSTORE_BASE64 not set — release builds will use debug signing."
  exit 0
fi

: "${KEYSTORE_PASSWORD:?KEYSTORE_PASSWORD is required when keystore is provided}"
: "${KEY_PASSWORD:?KEY_PASSWORD is required when keystore is provided}"
: "${KEY_ALIAS:?KEY_ALIAS is required when keystore is provided}"

KEYSTORE_PATH="android/app/upload-keystore.jks"
echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > "$KEYSTORE_PATH"

cat > android/key.properties <<EOF
storePassword=${KEYSTORE_PASSWORD}
keyPassword=${KEY_PASSWORD}
keyAlias=${KEY_ALIAS}
storeFile=app/upload-keystore.jks
EOF

echo "Android signing configured for alias ${KEY_ALIAS}."
