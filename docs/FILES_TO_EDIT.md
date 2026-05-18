# Firefox Source Files To Edit

The exact context changes by Firefox revision. Use this as the source-edit checklist for the selected ESR or release branch.

## Branding

Add:

```text
browser/branding/aura/configure.sh
browser/branding/aura/branding.nsi
browser/branding/aura/locales/en-US/brand.ftl
browser/branding/aura/pref/firefox-branding.js
browser/branding/aura/content/about-logo.svg
```

Edit:

```text
browser/confvars.sh
browser/moz.configure
```

Expected changes:

- Set the branding directory to `browser/branding/aura`.
- Set visible display name to `AuRA Browser`.
- Set executable/app basename to an AuRA-specific value such as `aurabrowser` / `AuRABrowser`.
- Set vendor to `AuRA` from `browser/moz.configure` with `imply_option`, not from `confvars.sh`.
- Set profile folder to `AuRA Browser` from `browser/moz.configure` with `imply_option`, not from `confvars.sh`.
- Set the app UA name from `browser/moz.configure` with `imply_option`, not from `confvars.sh`.
- Set macOS bundle ID to an AuRA-owned reverse-DNS identifier such as `io.aura.browser`.
- Keep the Firefox app ID at first if AMO compatibility is the priority, then revisit once extension testing is complete.
- Replace every inherited branding image from `unofficial` with AuRA-owned artwork before release.

## About Page

Add:

```text
browser/base/content/aboutAura.html
browser/base/content/aboutAura.css
```

Edit one or more of these, depending on Firefox version:

```text
browser/base/jar.mn
browser/components/about/AboutRedirector.cpp
browser/components/about/components.conf
```

Expected changes:

- Package `aboutAura.html` and `aboutAura.css` into `browser.jar`.
- Register `about:aura` to load `chrome://browser/content/aboutAura.html`.
- Use conservative about flags: linkable, safe for untrusted content, and script only if needed.
- The macOS `prepare-firefox-source.sh` helper applies these edits automatically for current Firefox source layout.

## Privacy Defaults

Add:

```text
browser/app/profile/aura.js
```

Edit:

```text
browser/app/profile/firefox.js
```

Expected changes:

- Append the AuRA preference block or include the AuRA preference file if supported by the target revision.
- Disable telemetry upload, studies, sponsored suggestions, and nonessential recommendation surfaces.
- Keep security services and extension compatibility services enabled.
- Copy `distribution/policies.json` into the Firefox source and packaged app distribution directory.

## Installer And Package Metadata

Review:

```text
browser/installer/windows/nsis/
browser/installer/package-manifest.in
browser/branding/aura/branding.nsi
browser/app/macbuild/
browser/branding/aura/
toolkit/mozapps/installer/
```

Expected changes:

- Package name and installer UI say AuRA Browser.
- Company/product metadata uses AuRA names.
- No Firefox/Mozilla logos are copied into final artifacts.
- macOS `.app`, helper apps, bundle identifier, `.dmg`, and icons use AuRA-owned names and assets.

## Release Engineering Later

Review before public release:

```text
taskcluster/
browser/config/
browser/locales/
build/
```

Expected changes:

- Add AuRA update channels.
- Add signing/notarization flows.
- Add update server URLs.
- Keep third-party notices and source license obligations.
