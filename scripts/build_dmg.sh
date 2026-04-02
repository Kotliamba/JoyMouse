#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
usage: ./scripts/build_dmg.sh <path/to/JoyMouse.app>

Notarization auth:
  Preferred:
    export NOTARYTOOL_PROFILE="joymouse-notary"

  Or use App Store Connect API key variables:
    export APP_API_KEY_PATH="/path/to/AuthKey_ABC123XYZ.p8"
    export APP_API_KEY_ID="ABC123XYZ"
    export APP_API_ISSUER="00000000-0000-0000-0000-000000000000"
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: Missing required command: $1"
    exit 1
  fi
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

require_command git
require_command codesign
require_command dmgbuild
require_command xcrun

SRC_APP_PATH="${1}"
APP_NAME="$(basename "${SRC_APP_PATH}")"
if [ "${APP_NAME}" != "JoyMouse.app" ]; then
  echo "error: App name must be 'JoyMouse.app'"
  exit 2
fi

if [ ! -d "${SRC_APP_PATH}" ]; then
  echo "error: App not found at ${SRC_APP_PATH}"
  exit 3
fi

VERSION="$(git describe --tags --abbrev=0 --match "v*.*.*" || true)"
if [ -z "${VERSION}" ]; then
  echo "error: version tag not found"
  exit 4
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="${PROJECT_ROOT}/dmg"
APP_PATH="${TMP_DIR}/JoyMouse.app"
DMG_PATH="${TMP_DIR}/JoyMouse-${VERSION}.dmg"
HELPER_PATH="${SRC_APP_PATH}/Contents/Library/LoginItems/JoyMouseLauncher.app"
DMG_SIGN_IDENTITY="${DMG_SIGN_IDENTITY:-Developer ID Application}"

NOTARY_ARGS=()
if [ -n "${NOTARYTOOL_PROFILE:-}" ]; then
  NOTARY_ARGS=(--keychain-profile "${NOTARYTOOL_PROFILE}")
elif [ -n "${APP_API_KEY_PATH:-}" ] && [ -n "${APP_API_KEY_ID:-}" ] && [ -n "${APP_API_ISSUER:-}" ]; then
  NOTARY_ARGS=(--key "${APP_API_KEY_PATH}" --key-id "${APP_API_KEY_ID}" --issuer "${APP_API_ISSUER}")
else
  echo "error: Missing notarization credentials."
  echo "Set NOTARYTOOL_PROFILE or APP_API_KEY_PATH + APP_API_KEY_ID + APP_API_ISSUER."
  exit 5
fi

echo "Source app path: ${SRC_APP_PATH}"

echo "Verifying signed app..."
codesign -dv --verbose=4 "${SRC_APP_PATH}" >/dev/null
if [ ! -d "${HELPER_PATH}" ]; then
  echo "error: Embedded helper app missing at ${HELPER_PATH}"
  exit 6
fi

echo "Copying app..."
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"
cp -Rp "${SRC_APP_PATH}" "${APP_PATH}"

echo "Creating DMG at ${DMG_PATH}"
dmgbuild -s "${PROJECT_ROOT}/scripts/dmg_settings.py" JoyMouse "${DMG_PATH}"

echo "Signing DMG..."
codesign -f -o runtime --timestamp -s "${DMG_SIGN_IDENTITY}" "${DMG_PATH}"

echo "Submitting DMG for notarization..."
xcrun notarytool submit "${NOTARY_ARGS[@]}" --wait --timeout 30m "${DMG_PATH}"

echo "Stapling notarization ticket..."
xcrun stapler staple "${DMG_PATH}"

echo "Validating stapled ticket..."
xcrun stapler validate "${DMG_PATH}"

echo "Done: ${DMG_PATH}"
