# Privacy And Optimization Defaults

AuRA Browser should be privacy-focused without breaking modern websites or Firefox extension compatibility.

## Starter Preferences

The starter preference file is:

```text
overlays/mozilla-central/browser/app/profile/aura.js
```

It disables:

- Telemetry upload and archived telemetry.
- Firefox Studies / Normandy experiments.
- New tab telemetry.
- Sponsored URL bar suggestions.
- Pocket recommendations.
- Default browser prompt noise.

It enables or keeps:

- Tracking protection in normal and private browsing.
- HTTPS-Only mode in private windows.
- Cookie behavior compatible with modern Firefox defaults.
- WebExtension APIs.
- Safe Browsing and other security-critical systems.

## Do Not Over-Optimize By Breaking Users

Avoid defaulting these unless you are willing to own compatibility fallout:

- `privacy.resistFingerprinting`
- Disabling all third-party cookies beyond Firefox's current defaults.
- Disabling JavaScript, WebGL, WASM, WebRTC, service workers, or HTTP/3.
- Removing Remote Settings.
- Removing Safe Browsing.
- Removing the password manager.

## Startup And Memory Principles

- Prefer Firefox ESR for stable downstream maintenance.
- Disable experiments, studies, telemetry upload, and sponsored content first.
- Avoid invasive changes to Gecko, SpiderMonkey, networking, and extension internals.
- Measure before changing core services.
- Use `about:processes`, profiler traces, startup cache metrics, and Talos-style benchmarks for real optimization decisions.

## Enterprise Policy Example

The example `distribution/policies.json` is useful for packaged test builds and managed installs. The macOS preparation/build scripts copy it into the Firefox source tree and then into the built `.app` under `Contents/Resources/distribution/policies.json`. It is not a substitute for source-level defaults, but it helps validate the privacy posture of developer builds.

Reference: https://mozilla.github.io/policy-templates/
