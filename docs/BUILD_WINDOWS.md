# Windows Build Instructions

These instructions assume AuRA Browser is developed as a fork or downstream patch stack on top of Firefox source. Keep this repository beside, not inside, the Firefox checkout.

## 1. Install Prerequisites

Follow Mozilla's official Windows build documentation:

https://firefox-source-docs.mozilla.org/setup/windows_build.html

Use a short source path without spaces for Firefox itself, for example:

```text
C:\mozilla-source\firefox
```

## 2. Bootstrap Firefox Source

From a MozillaBuild shell, use Mozilla's bootstrap flow:

```bash
cd c:/
mkdir mozilla-source
cd mozilla-source
wget https://raw.githubusercontent.com/mozilla-firefox/firefox/refs/heads/main/python/mozboot/bin/bootstrap.py
python3 bootstrap.py
```

Choose the Firefox branch deliberately:

- Use the latest ESR branch for a calmer downstream product.
- Use central/nightly only when you can absorb frequent source churn.
- If you maintain the fork with Mercurial instead, `mozilla-unified` is still a workable upstream checkout as long as `mach` is present.

## 3. Apply AuRA Overlay

From PowerShell in this repository:

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\apply-aura-overlay.ps1" -FirefoxSource "C:\mozilla-source\firefox"
```

This copies starter files into:

- `browser/branding/aura/`
- `browser/base/content/aboutAura.*`
- `browser/app/profile/aura.js`

If `browser/branding/aura` does not exist, the script first seeds it from `browser/branding/unofficial` so required branding file names are present. Treat any inherited art as temporary local-build scaffolding, not release branding.

## 4. Configure The Build

For full builds:

```powershell
Copy-Item ".\mozconfigs\aura-windows-release.mozconfig" "C:\mozilla-source\firefox\.mozconfig"
```

For faster front-end iteration:

```powershell
Copy-Item ".\mozconfigs\aura-windows-artifact.mozconfig" "C:\mozilla-source\firefox\.mozconfig"
```

Artifact builds are good for UI, JS, CSS, and branding iteration. They are not enough for C++ changes such as `AboutRedirector.cpp`; use a full build when adding `about:aura`.

## 5. Port Patch Templates

Apply or manually port:

```text
patches/0001-aura-branding-and-about-page.patch
patches/0002-aura-privacy-defaults.patch
```

If patch context fails, open [FILES_TO_EDIT.md](FILES_TO_EDIT.md) and make the equivalent edits against your chosen Firefox revision.

## 6. Build And Package

From the Firefox source directory in a MozillaBuild shell:

```bash
./mach build
./mach run
./mach package
```

For incremental front-end changes:

```bash
./mach build faster
./mach run
```

## 7. Smoke Tests

Before distributing any build, verify:

- The app name, window title, installer, executable, and profile folder say AuRA Browser.
- No Mozilla or Firefox logo assets are visible.
- `about:aura` loads.
- `about:addons` works.
- Signed extensions from addons.mozilla.org install and run.
- Private windows work.
- Bookmarks, history, downloads, password manager, search settings, and theme switching work.
- Telemetry, studies, and sponsored suggestion defaults are disabled.
- Safe Browsing, certificate checks, and add-on blocklists still work.

## 8. Packaging Reality Check

Windows release builds also need code signing, update infrastructure, crash reporting policy, and a security response process. Do not disable Firefox's updater in public builds until AuRA has its own safe update mechanism.
