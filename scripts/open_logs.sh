#!/usr/bin/env bash
set -euo pipefail

BUNDLE_ID="${BUNDLE_ID:-com.grigorymordokhovich.weather}"
STYLE="${STYLE:-compact}"
LAST_WINDOW="${LAST_WINDOW:-1h}"

exec log stream \
  --style "$STYLE" \
  --level debug \
  --predicate "subsystem == \"$BUNDLE_ID\" OR processImagePath CONTAINS[c] \"/Weather.app/\" OR eventMessage CONTAINS[c] \"$BUNDLE_ID\"" \
  --last "$LAST_WINDOW"
