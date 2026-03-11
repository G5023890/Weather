#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${APP_PATH:-/Applications/Weather.app}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found at: $APP_PATH" >&2
  echo "Build and install it first with ./scripts/build_and_install_app.sh" >&2
  exit 1
fi

open "$APP_PATH"
