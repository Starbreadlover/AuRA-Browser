#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 /path/to/firefox-source [release|artifact] [--run] [--package]"
  echo
  echo "Default: build only. Add --run to launch locally and --package to create a DMG."
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -lt 1 ]; then
  usage
  exit 64
fi

firefox_source=$1
shift
config=release
run_after=false
package_after=false

if [ "${1:-}" = "release" ] || [ "${1:-}" = "artifact" ]; then
  config=$1
  shift
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --run)
      run_after=true
      ;;
    --package)
      package_after=true
      ;;
    *)
      usage
      exit 64
      ;;
  esac
  shift
done

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

case "$config" in
  release)
    mozconfig_name="aura-macos-release.mozconfig"
    ;;
  artifact)
    mozconfig_name="aura-macos-artifact.mozconfig"
    ;;
  *)
    usage
    exit 64
    ;;
esac

mach_path="$firefox_source/mach"
mozconfig_source="$repo_root/mozconfigs/$mozconfig_name"
mozconfig_target="$firefox_source/.mozconfig"

if [ ! -f "$mach_path" ]; then
  echo "FirefoxSource does not look like a Firefox checkout: $firefox_source" >&2
  exit 1
fi

cp "$mozconfig_source" "$mozconfig_target"
echo "Copied $mozconfig_name to $mozconfig_target"

cd "$firefox_source"
./mach build

latest_app=$(ls -td "$firefox_source"/obj-*/dist/*.app 2>/dev/null | head -n 1 || true)
if [ -n "$latest_app" ]; then
  mkdir -p "$latest_app/Contents/Resources/distribution"
  cp "$repo_root/distribution/policies.json" "$latest_app/Contents/Resources/distribution/policies.json"
  echo "Installed policies.json into $latest_app"
else
  echo "Could not find built .app under obj-*/dist yet; policies are still present in source distribution/."
fi

if [ "$package_after" = true ]; then
  ./mach package
  echo
  echo "Package output should be under:"
  echo "  $firefox_source/obj-*/dist/*.dmg"
fi

if [ "$run_after" = true ]; then
  ./mach run
fi
