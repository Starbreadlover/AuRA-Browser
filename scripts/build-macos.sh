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
release_dmg_name="AuraV0.2.0.dmg"

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

install_policies_into_apps() {
  local installed=false
  local app
  local dist_bin

  for dist_bin in "$firefox_source"/obj-*/dist/bin; do
    if [ ! -d "$dist_bin" ]; then
      continue
    fi

    mkdir -p "$dist_bin/distribution"
    cp "$repo_root/distribution/policies.json" "$dist_bin/distribution/policies.json"
    echo "Installed policies.json into $dist_bin/distribution"
    installed=true
  done

  for app in "$firefox_source"/obj-*/dist/*.app "$firefox_source"/obj-*/dist/*/"AuRA Browser.app"; do
    if [ ! -d "$app/Contents/Resources" ]; then
      continue
    fi

    mkdir -p "$app/Contents/Resources/distribution"
    cp "$repo_root/distribution/policies.json" "$app/Contents/Resources/distribution/policies.json"
    echo "Installed policies.json into $app"
    installed=true
  done

  if [ "$installed" = false ]; then
    echo "Could not find built AuRA Browser.app under obj-*/dist yet; policies are still present in source distribution/."
  fi
}

cp "$mozconfig_source" "$mozconfig_target"
echo "Copied $mozconfig_name to $mozconfig_target"

cd "$firefox_source"
./mach build

install_policies_into_apps

if [ "$package_after" = true ]; then
  ./mach package
  latest_dmg=$(ls -t "$firefox_source"/obj-*/dist/*.dmg 2>/dev/null | head -n 1 || true)
  if [ -n "$latest_dmg" ]; then
    dist_dir="$(dirname "$latest_dmg")"
    release_dmg="$dist_dir/$release_dmg_name"
    all_versions_dir="$dist_dir/All Versions"
    cp "$latest_dmg" "$release_dmg"
    echo "Named release DMG: $release_dmg"
    mkdir -p "$all_versions_dir"
    cp "$release_dmg" "$all_versions_dir/$release_dmg_name"
    echo "Archived release DMG: $all_versions_dir/$release_dmg_name"
  fi
  echo
  echo "Package output should be under:"
  echo "  $firefox_source/obj-*/dist/$release_dmg_name"
fi

if [ "$run_after" = true ]; then
  ./mach run
fi
