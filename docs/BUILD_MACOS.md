# macOS Build Instructions

These instructions turn this starter kit into a real local Firefox/Gecko-based AuRA Browser build on macOS. Keep this repository beside, not inside, the Firefox checkout.

## 1. Install Prerequisites

Follow Mozilla's official macOS build documentation:

https://firefox-source-docs.mozilla.org/setup/macos_build.html

Mozilla currently expects:

- A recent supported macOS release.
- Homebrew.
- Xcode from the App Store.
- Xcode command-line setup:

```bash
sudo xcode-select --switch /Applications/Xcode.app
sudo xcodebuild -license
```

Install Homebrew from https://brew.sh/ if you do not already have it:

```bash
command -v brew >/dev/null || echo "Install Homebrew from https://brew.sh/ first"
```

Use a short source path for Firefox itself, for example:

```text
~/mozilla-source/firefox
```

## 2. Copy-Paste Build Flow

From this repository:

```bash
cd "/Users/shrod/projects/AuRA Browser"
./scripts/bootstrap-firefox-macos.sh "$HOME/mozilla-source"
./scripts/prepare-firefox-source.sh "$HOME/mozilla-source/firefox" release
./scripts/build-macos.sh "$HOME/mozilla-source/firefox" release --run --package
```

During bootstrap, choose Firefox Desktop. For the first AuRA build, choose a full build rather than artifact mode because `about:aura` changes C++ registration code.

## 3. What The Scripts Do

`bootstrap-firefox-macos.sh`:

- Downloads Mozilla's official bootstrap script.
- Runs the interactive Firefox source bootstrap.
- Creates or updates the Firefox checkout under `~/mozilla-source/firefox`.

`prepare-firefox-source.sh`:

- Copies AuRA overlay files into Firefox source.
- Seeds `browser/branding/aura` from Firefox's `unofficial` branding if needed.
- Sets `browser/confvars.sh` default branding to `browser/branding/aura`.
- Sets AuRA project-only identity flags in `browser/moz.configure`.
- Adds `aboutAura.html` and `aboutAura.css` to `browser/base/jar.mn`.
- Registers `about:aura` in `browser/components/about/AboutRedirector.cpp`.
- Registers `about:aura` in `browser/components/about/components.conf`.
- Appends AuRA privacy defaults to `browser/app/profile/firefox.js`.
- Copies `distribution/policies.json` into the Firefox source tree.
- Copies the selected AuRA macOS mozconfig to `.mozconfig`.

`build-macos.sh`:

- Runs `./mach build`.
- Copies `distribution/policies.json` into the built `.app`.
- Runs the browser when `--run` is passed.
- Creates a distributable `.dmg` when `--package` is passed.

## 4. Manual Commands, If You Prefer

Bootstrap source with Mozilla's flow:

```bash
mkdir -p "$HOME/mozilla-source"
cd "$HOME/mozilla-source"
curl -L https://raw.githubusercontent.com/mozilla-firefox/firefox/refs/heads/main/python/mozboot/bin/bootstrap.py -O
python3 bootstrap.py
```

Direct Git clone alternative:

```bash
mkdir -p "$HOME/mozilla-source"
git clone https://github.com/mozilla-firefox/firefox.git "$HOME/mozilla-source/firefox"
cd "$HOME/mozilla-source/firefox"
./mach bootstrap
```

Prepare and build:

```bash
cd "/Users/shrod/projects/AuRA Browser"
./scripts/prepare-firefox-source.sh "$HOME/mozilla-source/firefox" release
./scripts/build-macos.sh "$HOME/mozilla-source/firefox" release --run --package
```

The resulting package should be under:

```text
~/mozilla-source/firefox/obj-*/dist/AuraV0.1.1.dmg
```

## 5. Artifact Builds Later

After a full build has proven the C++ registration changes, artifact mode is useful for faster UI/branding iteration:

```bash
./scripts/prepare-firefox-source.sh "$HOME/mozilla-source/firefox" artifact
./scripts/build-macos.sh "$HOME/mozilla-source/firefox" artifact --run
```

## 6. Branch Choice

- Use the latest ESR branch for a calmer downstream product.
- Use central/nightly only when you can absorb frequent source churn.
- Keep Gecko, WebExtensions, add-on manager, XPInstall, signed XPI handling, and Remote Settings intact for extension compatibility.

## 7. Build, Run, And Package Without Helper

From the Firefox source directory:

```bash
./mach build
./mach run
./mach package
```

Packaged macOS builds are emitted under `obj-*/dist/AuraV0.1.1.dmg`. Use the packaged `.dmg` to test on another Mac because the raw development `.app` can contain symlinks to the build tree.

## 8. Signing And Notarization

Local `./mach run` development does not usually need production signing. Public macOS distribution is different:

- Apple Silicon development builds may rely on ad-hoc signing during compilation.
- Some features, including passkey-related behavior, depend on signing and entitlements.
- Public `.dmg` distribution needs AuRA-owned Developer ID signing and notarization.
- Do not use Mozilla signing identities, provisioning profiles, app IDs, or notarization credentials.

Mozilla documents local signing here:

https://firefox-source-docs.mozilla.org/contributing/signing/signing_macos_build.html

## 9. Smoke Tests

Before distributing any macOS build, verify:

- The `.app`, app menu, window title, About UI, profile folder, and `.dmg` say AuRA Browser.
- Bundle identifier is AuRA-owned, for example `io.aura.browser`.
- No Mozilla or Firefox logo assets are visible.
- `about:aura` loads.
- `about:addons` works.
- Signed extensions from addons.mozilla.org install and run.
- Private windows work.
- Bookmarks, history, downloads, password manager, search settings, and theme switching work.
- Only DuckDuckGo and Startpage are available as search providers.
- Telemetry, studies, and sponsored suggestion defaults are disabled.
- Safe Browsing, certificate checks, and add-on blocklists still work.
