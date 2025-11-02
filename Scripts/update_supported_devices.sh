#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
README="$ROOT_DIR/README.md"

if ! command -v airbattery >/dev/null 2>&1; then
  echo "airbattery CLI not found in PATH. Build the CLI or install the app's CLI first." >&2
  echo "For example: open in Xcode and build the 'abt' target, then symlink to 'airbattery'." >&2
  exit 1
fi

TMP_MD="$(mktemp)"
airbattery supported > "$TMP_MD"

awk -v repl_file="$TMP_MD" '
  BEGIN {inblk=0}
  /^<!-- SUPPORTED_DEVICES:START -->/ {print; inblk=1; while ((getline line < repl_file) > 0) print line; next}
  /^<!-- SUPPORTED_DEVICES:END -->/ {inblk=0; print; next}
  inblk==0 {print}
' "$README" > "$README.tmp"

mv "$README.tmp" "$README"
echo "Updated README Supported Devices section."

