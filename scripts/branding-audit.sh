#!/usr/bin/env bash
set -euo pipefail

audit_path=${1:-./dist}

if [ ! -e "$audit_path" ]; then
  echo "Path not found: $audit_path" >&2
  exit 1
fi

if grep -RIn --binary-files=without-match -E "Firefox|Mozilla|firefox-logo|mozilla-logo" "$audit_path"; then
  echo "Potential branding issues found." >&2
  exit 1
fi

echo "No obvious protected branding strings found in $audit_path"
