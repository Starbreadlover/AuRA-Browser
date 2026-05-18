# Firefox Extension Compatibility

AuRA Browser should remain compatible with Firefox WebExtensions from addons.mozilla.org as much as possible. Treat extension compatibility as a core product contract, not as a cleanup area.

## Preserve These Areas

- `browser/components/extensions`
- `toolkit/components/extensions`
- `toolkit/mozapps/extensions`
- XPInstall and signed XPI verification
- Add-on manager UI and permissions prompts
- Extension storage, native messaging, downloads, tabs, bookmarks, history, proxy, webRequest, declarativeNetRequest, and theme APIs
- Remote Settings data required for add-on blocklists and security

## Be Careful With App Identity

During early AuRA builds, prefer visible rebranding first and keep the Firefox application ID while validating AMO behavior. Some add-on compatibility paths and install flows may assume Firefox identity. If you later choose a custom app ID, expect to retest:

- AMO install button behavior
- Extension signing acceptance
- `strict_min_version` and `strict_max_version` checks
- Native messaging host manifests
- Enterprise extension policies
- Update URLs and blocklist behavior

## What To Disable

Good candidates:

- Telemetry upload
- Firefox Studies / Shield experiments
- Sponsored suggestions
- New tab telemetry
- Default browser background agent, if present and not needed

Avoid disabling:

- Add-on blocklists
- Certificate revocation and security updates
- Safe Browsing without a replacement
- Extension signing
- Remote Settings collections needed by security and compatibility systems

## Compatibility Test Matrix

Test at least:

- uBlock Origin
- Bitwarden or another password manager extension
- Dark Reader or another theme/content extension
- Privacy Badger or similar privacy add-on
- Tree Style Tab or a tabs/sidebar extension
- A native-messaging extension if AuRA supports that workflow

Test each in normal windows and private windows.

Reference: https://developer.mozilla.org/docs/Mozilla/Add-ons/WebExtensions
