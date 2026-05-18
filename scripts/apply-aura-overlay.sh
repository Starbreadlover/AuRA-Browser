#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 /path/to/firefox-source"
}

if [ "$#" -ne 1 ]; then
  usage
  exit 64
fi

firefox_source=$1
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
overlay_root="$repo_root/overlays/mozilla-central"
mach_path="$firefox_source/mach"
branding_base="$firefox_source/browser/branding/unofficial"
branding_target="$firefox_source/browser/branding/aura"

if [ ! -d "$overlay_root" ]; then
  echo "Overlay directory not found: $overlay_root" >&2
  exit 1
fi

if [ ! -f "$mach_path" ]; then
  echo "FirefoxSource does not look like a Firefox checkout: $firefox_source" >&2
  exit 1
fi

if [ -d "$branding_base" ] && [ ! -d "$branding_target" ]; then
  cp -R "$branding_base" "$branding_target"
  echo "Seeded browser/branding/aura from browser/branding/unofficial"
  echo "Replace inherited placeholder art before distributing AuRA Browser."
fi

while IFS= read -r file; do
  relative=${file#"$overlay_root/"}
  target="$firefox_source/$relative"
  mkdir -p "$(dirname "$target")"
  cp "$file" "$target"
  echo "Copied $relative"
done < <(find "$overlay_root" -type f | sort)

echo
echo "Overlay copied. Next:"
echo "1. Run ./scripts/prepare-firefox-source.sh \"$firefox_source\" release"
echo "2. Run ./scripts/build-macos.sh \"$firefox_source\" release --run --package"
