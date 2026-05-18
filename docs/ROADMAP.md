# AuRA Browser Roadmap

## Phase 0: Choose The Base

- Pick a Firefox ESR branch for the first product line.
- Keep a clean upstream remote and a small AuRA patch stack.
- Document licenses and third-party notices.
- Decide whether early builds keep the Firefox app ID for extension compatibility validation.

## Phase 1: Branding Foundation

- Add `browser/branding/aura`.
- Replace icons, logos, installer metadata, profile name, and visible product strings.
- Build with `--with-branding=browser/branding/aura`.
- Run a branding audit against final artifacts.

## Phase 2: Product Surface

- Add `about:aura`.
- Customize settings text where it references the product.
- Keep `about:addons`, bookmarks, downloads, history, password manager, and private browsing intact.
- Add dark and light theme QA.

## Phase 3: Privacy Defaults

- Disable telemetry upload, studies, sponsored suggestions, and nonessential background recommendations.
- Keep security-critical services.
- Package enterprise policy defaults for managed deployments.
- Add privacy regression checks.

## Phase 4: Performance

- Establish baseline startup, idle memory, page-load, and extension-load metrics.
- Remove or disable only services proven unnecessary.
- Avoid changing Gecko or extension internals without benchmark evidence.

## Phase 5: Extension Compatibility

- Test common AMO extensions.
- Test native messaging.
- Test private window extension permissions.
- Test extension updates and blocklist behavior.
- Keep an explicit compatibility report for every release.

## Phase 6: macOS Support

- Add macOS mozconfigs and build documentation.
- Use an AuRA-owned bundle identifier such as `io.aura.browser`.
- Replace all inherited app bundle and DMG artwork.
- Add Developer ID signing and notarization for public distribution.
- Test Apple Silicon and Intel Macs if universal packaging is required.

## Phase 7: Release Engineering

- Add Windows code signing.
- Add macOS signing and notarization.
- Add update infrastructure.
- Add crash reporting policy.
- Add reproducible build notes.
- Add Linux packaging after Windows and macOS are stable.
