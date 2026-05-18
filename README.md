# AuRA Browser

AuRA Browser is a desktop browser project built on Mozilla Firefox and the Gecko engine. It keeps Firefox WebExtension compatibility while replacing the visible product branding with AuRA Browser branding, icons, privacy defaults, and project-specific packaging.

The goal is a clean, fast, privacy-focused browser that still supports the Firefox add-on ecosystem.

## What AuRA Browser Is

- A Gecko-based desktop browser.
- Compatible with Firefox WebExtensions and addons.mozilla.org.
- Branded as AuRA Browser in the app name, menus, icons, profile folder, and internal pages.
- Configured with privacy-focused defaults for telemetry, studies, sponsored surfaces, and recommendations.
- Built from Firefox source with AuRA overlays, patches, and packaging configuration.

## Beta Status

AuRA Browser is currently in beta. The beta build is for testing and feedback, not production use.

Current beta target:

- macOS only
- Local `.dmg` installer package
- Firefox add-on compatibility preserved
- No public auto-update channel yet

Windows support files are included for development builds, but the public beta install flow is macOS only right now.

## Install The Beta On macOS

[![Install AuRA Browser on macOS](https://img.shields.io/badge/Install%20AuRA%20Browser-macOS-blue?style=for-the-badge&logo=apple)](https://github.com/Starbreadlover/AuRA-Browser/releases/latest)

**One-command install** — paste this into Terminal and press Return:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Starbreadlover/AuRA-Browser/main/scripts/install-macos.sh)"
```

The script will:
1. Fetch the latest release from GitHub automatically.
2. Download the `.dmg` to a temporary folder.
3. Mount it, copy `AuRA Browser.app` to `/Applications`, and clean up.

After install, right-click `AuRA Browser` in Applications and choose **Open** on first launch — macOS may show a security prompt for beta builds that are not yet notarized.

To update to a newer beta, just run the same command again — it will replace the existing installation.

<details>
<summary>Manual install (without Terminal)</summary>

1. Go to the [GitHub Releases page](https://github.com/Starbreadlover/AuRA-Browser/releases/latest).
2. Download the latest macOS beta `.dmg` file.
3. Open the downloaded `.dmg`.
4. Drag `AuRA Browser.app` into your `Applications` folder.
5. Control-click or right-click `AuRA Browser.app`, then choose `Open`.
6. Confirm the macOS security prompt if it appears.

</details>

## Add-ons

AuRA Browser is designed to work with Firefox extensions from addons.mozilla.org. The browser keeps the Firefox application ID and Firefox-compatible user-agent identity for add-on compatibility, while the visible app branding remains AuRA Browser.

## Build From Source

This repository does not vendor the full Firefox source tree. It contains AuRA-specific overlays, branding assets, mozconfigs, policies, and helper scripts that apply to a separate Firefox checkout.

For macOS development builds:

```bash
cd "/Users/shrod/projects/AuRA Browser"
./scripts/bootstrap-firefox-macos.sh "$HOME/mozilla-source"
./scripts/prepare-firefox-source.sh "$HOME/mozilla-source/firefox" release
./scripts/build-macos.sh "$HOME/mozilla-source/firefox" release --run --package
```

The packaged macOS build is created in the Firefox object directory, usually:

```text
$HOME/mozilla-source/firefox/obj-aura-macos-release/dist/
```

For detailed build instructions, see:

- [macOS build guide](docs/BUILD_MACOS.md)
- [Windows build guide](docs/BUILD_WINDOWS.md)
- [files to edit](docs/FILES_TO_EDIT.md)

## Project Layout

```text
distribution/   Enterprise policy defaults
docs/           Build, branding, privacy, and compatibility notes
mozconfigs/     Firefox build configuration files
overlays/       AuRA files copied into the Firefox source tree
patches/        Patch templates for Firefox source changes
scripts/        Bootstrap, overlay, build, and audit helpers
```

## Legal Note

AuRA Browser is an independent browser project based on open-source Firefox and Gecko technology. Mozilla, Firefox, and related logos are trademarks of Mozilla. AuRA Browser must not ship Mozilla or Firefox branding, logos, installer art, or language that implies Mozilla endorsement.

See [branding and legal notes](docs/BRANDING_AND_LEGAL.md) before distributing builds.
