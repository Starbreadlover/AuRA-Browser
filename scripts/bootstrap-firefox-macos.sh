#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [parent-directory]"
  echo
  echo "Default parent-directory: \$HOME/mozilla-source"
  echo "Mozilla bootstrap will create or update a Firefox checkout under that directory."
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

source_parent=${1:-"$HOME/mozilla-source"}
bootstrap_url="https://raw.githubusercontent.com/mozilla-firefox/firefox/refs/heads/main/python/mozboot/bin/bootstrap.py"

mkdir -p "$source_parent"
cd "$source_parent"

if ! command -v brew >/dev/null 2>&1; then
  echo "Warning: Homebrew was not found. Mozilla's macOS build docs require Homebrew."
  echo "Install it from https://brew.sh/ before bootstrapping if bootstrap fails."
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Warning: Xcode command line tools are not configured."
  echo "Install Xcode, then run:"
  echo "  sudo xcode-select --switch /Applications/Xcode.app"
  echo "  sudo xcodebuild -license"
fi

echo "Downloading Mozilla bootstrap script..."
curl -L "$bootstrap_url" -o bootstrap.py

echo
echo "Starting Mozilla Firefox bootstrap."
echo "When prompted, choose Firefox Desktop."
echo "For the first real AuRA build, choose a full build, not artifact mode,"
echo "because AuRA registers a new about: page in C++."
echo

python3 bootstrap.py

echo
echo "Bootstrap finished."
echo "Expected Firefox source path: $source_parent/firefox"
echo "Next:"
echo "  ./scripts/prepare-firefox-source.sh \"$source_parent/firefox\" release"
