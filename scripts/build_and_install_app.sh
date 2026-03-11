#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

APP_DISPLAY_NAME="${APP_DISPLAY_NAME:-Weather}"
EXECUTABLE_NAME="${EXECUTABLE_NAME:-Weather}"
BUNDLE_ID="${BUNDLE_ID:-com.grigorymordokhovich.weather}"
SCHEME_NAME="${SCHEME_NAME:-Weather}"
CONFIGURATION="${CONFIGURATION:-Release}"
PROJECT_FILE="${PROJECT_FILE:-Weather.xcodeproj}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$HOME/Library/Developer/Xcode/DerivedData/${APP_DISPLAY_NAME}}"
APP_DIR="${APP_DIR:-dist/${APP_DISPLAY_NAME}.app}"
INSTALL_DIR="${INSTALL_DIR:-/Applications/${APP_DISPLAY_NAME}.app}"
LEGACY_INSTALL_DIR="${LEGACY_INSTALL_DIR:-/Applications/Weather.app}"
ICON_SOURCE="${ICON_SOURCE:-}"
SKIP_SIGN="${SKIP_SIGN:-0}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
DEVELOPER_DIR_OVERRIDE="${DEVELOPER_DIR_OVERRIDE:-}"
RESOLVED_SIGN_IDENTITY=""
STAGING_ROOT=""
APP_STAGE=""
BUILD_APP_PATH=""
APP_SLUG="$(printf '%s' "$APP_DISPLAY_NAME" | tr '[:upper:]' '[:lower:]')"

BUILD_LOG="${BUILD_LOG:-/tmp/${APP_SLUG}-xcodebuild.log}"
KEYCHAIN_SERVICE="${KEYCHAIN_SERVICE:-com.grigorymordokhovich.weather.openweather}"
KEYCHAIN_ACCOUNT="${KEYCHAIN_ACCOUNT:-default}"
SECRETS_FILE="${SECRETS_FILE:-$PROJECT_DIR/Config/Secrets.xcconfig}"

log() {
  echo "[build] $*"
}

extract_api_key() {
  if [[ -f "$SECRETS_FILE" ]]; then
    awk -F= '/^[[:space:]]*WEATHER_API_KEY[[:space:]]*=/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}' "$SECRETS_FILE"
  fi
}

store_api_key_in_keychain() {
  local api_key="$1"

  if [[ -z "$api_key" ]]; then
    return 0
  fi

  log "Storing OpenWeather API key in login Keychain"
  security add-generic-password \
    -U \
    -a "$KEYCHAIN_ACCOUNT" \
    -s "$KEYCHAIN_SERVICE" \
    -w "$api_key" >/dev/null
}

activate_xcode() {
  if [[ -n "$DEVELOPER_DIR_OVERRIDE" ]]; then
    export DEVELOPER_DIR="$DEVELOPER_DIR_OVERRIDE"
    log "Using DEVELOPER_DIR override: $DEVELOPER_DIR"
    return 0
  fi

  if [[ -d "/Applications/Xcode-beta.app/Contents/Developer" ]]; then
    export DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer"
    log "Using Xcode beta developer dir"
    return 0
  fi

  if [[ -d "/Applications/Xcode.app/Contents/Developer" ]]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    log "Using Xcode developer dir"
  fi
}

ensure_xcode_project() {
  if [[ -f "$PROJECT_DIR/project.yml" ]]; then
    if [[ ! -d "$PROJECT_FILE" || "$PROJECT_DIR/project.yml" -nt "$PROJECT_FILE/project.pbxproj" ]]; then
      log "Generating Xcode project with xcodegen"
      xcodegen generate
    fi
  fi
}

sign_bundle_if_needed() {
  local bundle="$1"

  if [[ "$SKIP_SIGN" == "1" ]]; then
    log "Skipping codesign (SKIP_SIGN=1)"
    return 0
  fi

  if [[ -n "$RESOLVED_SIGN_IDENTITY" ]]; then
    log "Signing with identity: $RESOLVED_SIGN_IDENTITY"
    codesign --force --deep --options runtime --sign "$RESOLVED_SIGN_IDENTITY" "$bundle"
  else
    log "No Apple Development identity found; using ad-hoc signature"
    codesign --force --deep --sign - "$bundle"
  fi

  codesign --verify --deep --strict "$bundle"
}

verify_bundle_id() {
  local bundle="$1"
  local actual_bundle_id

  actual_bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$bundle/Contents/Info.plist" 2>/dev/null || true)"
  if [[ "$actual_bundle_id" != "$BUNDLE_ID" ]]; then
    echo "Bundle identifier mismatch: expected $BUNDLE_ID, got ${actual_bundle_id:-<missing>}" >&2
    exit 1
  fi
}

resolve_sign_identity() {
  if [[ "$SKIP_SIGN" == "1" ]]; then
    return 0
  fi

  if [[ -n "$SIGN_IDENTITY" ]]; then
    RESOLVED_SIGN_IDENTITY="$SIGN_IDENTITY"
    return 0
  fi

  if [[ -d "$INSTALL_DIR" ]]; then
    local existing existing_info
    existing_info="$(codesign -dv --verbose=4 "$INSTALL_DIR" 2>&1 || true)"
    existing="$(printf '%s\n' "$existing_info" | awk -F= '/^Authority=Apple Development: /{print $2}' | sed -n '1p')"
    if [[ -n "$existing" ]]; then
      RESOLVED_SIGN_IDENTITY="$existing"
      return 0
    fi
  fi

  local identities_output first_available
  identities_output="$(security find-identity -v -p codesigning 2>/dev/null || true)"
  first_available="$(printf '%s\n' "$identities_output" | awk -F '"' '/Apple Development: /{print $2; exit}')"
  if [[ -n "$first_available" ]]; then
    RESOLVED_SIGN_IDENTITY="$first_available"
  fi
}

build_app() {
  log "Building ${SCHEME_NAME} (${CONFIGURATION})"
  xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME_NAME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build > "$BUILD_LOG"

  BUILD_APP_PATH="$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}/${APP_DISPLAY_NAME}.app"
  if [[ ! -d "$BUILD_APP_PATH" ]]; then
    echo "Built app not found: $BUILD_APP_PATH" >&2
    exit 1
  fi

  log "Built app bundle: $BUILD_APP_PATH"
}

resolve_sign_identity
if [[ -n "$RESOLVED_SIGN_IDENTITY" ]]; then
  log "Resolved signing identity: $RESOLVED_SIGN_IDENTITY"
fi

activate_xcode
ensure_xcode_project
build_app

STAGING_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/weather-build.XXXXXX")"
APP_STAGE="$STAGING_ROOT/${APP_DISPLAY_NAME}.app"
cleanup() {
  if [[ -n "$STAGING_ROOT" && -d "$STAGING_ROOT" ]]; then
    rm -rf "$STAGING_ROOT"
  fi
}
trap cleanup EXIT

rm -rf "$APP_STAGE"
/usr/bin/ditto --norsrc "$BUILD_APP_PATH" "$APP_STAGE"

if [[ -n "$ICON_SOURCE" && -f "$ICON_SOURCE" ]]; then
  log "Overriding app icon from: $ICON_SOURCE"
  mkdir -p "$APP_STAGE/Contents/Resources"
  /usr/bin/ditto --norsrc "$ICON_SOURCE" "$APP_STAGE/Contents/Resources/AppIcon.icns"
fi

xattr -c "$APP_STAGE" 2>/dev/null || true
xattr -cr "$APP_STAGE" 2>/dev/null || true
verify_bundle_id "$APP_STAGE"
sign_bundle_if_needed "$APP_STAGE"

mkdir -p "$(dirname "$APP_DIR")"
rm -rf "$APP_DIR"
/usr/bin/ditto --norsrc "$APP_STAGE" "$APP_DIR"

rm -rf "$INSTALL_DIR"
/usr/bin/ditto --norsrc "$APP_STAGE" "$INSTALL_DIR"
if [[ "$LEGACY_INSTALL_DIR" != "$INSTALL_DIR" ]]; then
  rm -rf "$LEGACY_INSTALL_DIR"
fi

xattr -cr "$INSTALL_DIR" || true
sign_bundle_if_needed "$INSTALL_DIR"
verify_bundle_id "$INSTALL_DIR"
store_api_key_in_keychain "$(extract_api_key)"

log "Built: $APP_DIR"
log "Installed: $INSTALL_DIR"
log "Build log: $BUILD_LOG"
