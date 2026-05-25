#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 /path/to/firefox-source [release|artifact]"
  echo
  echo "Use 'release' for the first real AuRA build because about:aura changes C++."
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
  exit 64
fi

firefox_source=$1
config=${2:-release}
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

if [ ! -f "$firefox_source/mach" ]; then
  echo "Firefox source not found or invalid: $firefox_source" >&2
  echo "Run ./scripts/bootstrap-firefox-macos.sh first." >&2
  exit 1
fi

echo "Applying AuRA overlay files..."
"$script_dir/apply-aura-overlay.sh" "$firefox_source"

echo "Installing AuRA mozconfig..."
cp "$repo_root/mozconfigs/$mozconfig_name" "$firefox_source/.mozconfig"

echo "Copying distribution policies..."
mkdir -p "$firefox_source/distribution"
cp "$repo_root/distribution/policies.json" "$firefox_source/distribution/policies.json"

echo "Patching Firefox source registration points..."
AURA_REPO_ROOT="$repo_root" FIREFOX_SOURCE="$firefox_source" python3 - <<'PY'
from pathlib import Path
import os
import re
import sys

root = Path(os.environ["FIREFOX_SOURCE"]).resolve()
repo = Path(os.environ["AURA_REPO_ROOT"]).resolve()

def fail(message):
    print(f"prepare-firefox-source: {message}", file=sys.stderr)
    sys.exit(1)

def read(path):
    try:
        return path.read_text()
    except FileNotFoundError:
        fail(f"required file not found: {path}")

def write_if_changed(path, text):
    old = read(path)
    if old != text:
        path.write_text(text)
        print(f"Patched {path.relative_to(root)}")
    else:
        print(f"Already current {path.relative_to(root)}")

def ensure_line_after_match(path, match_re, new_lines):
    text = read(path)
    missing_lines = [line for line in new_lines if line not in text]
    if not missing_lines:
        print(f"Already current {path.relative_to(root)}")
        return

    lines = text.splitlines(keepends=True)
    insert_at = None
    for i, line in enumerate(lines):
        if re.search(match_re, line):
            insert_at = i + 1
            break

    if insert_at is None:
        fail(f"could not find insertion point in {path}")

    lines[insert_at:insert_at] = [line + "\n" for line in missing_lines]
    write_if_changed(path, "".join(lines))

confvars = root / "browser/confvars.sh"
conf_text = read(confvars)
conf_text = re.sub(
    r"^(MOZ_APP_VENDOR|MOZ_APP_PROFILE|MOZ_APP_UA_NAME)=.*\n?",
    "",
    conf_text,
    flags=re.MULTILINE,
)
if "MOZ_BRANDING_DIRECTORY=" in conf_text:
    conf_text = re.sub(
        r"^MOZ_BRANDING_DIRECTORY=.*$",
        "MOZ_BRANDING_DIRECTORY=browser/branding/aura",
        conf_text,
        flags=re.MULTILINE,
    )
else:
    conf_text += "\nMOZ_BRANDING_DIRECTORY=browser/branding/aura\n"
write_if_changed(confvars, conf_text)

browser_configure = root / "browser/moz.configure"
browser_configure_text = read(browser_configure)
identity_start = "# >>> AuRA Browser project identity\n"
identity_end = "# <<< AuRA Browser project identity"
identity_block = (
    identity_start
    + 'imply_option("MOZ_APP_VENDOR", "AuRA")\n'
    + 'imply_option("MOZ_APP_PROFILE", "AuRA Browser")\n'
    + 'imply_option("MOZ_APP_UA_NAME", "Firefox")\n'
    + identity_end
)
if identity_start in browser_configure_text:
    browser_configure_text = re.sub(
        re.escape(identity_start) + r".*?" + re.escape(identity_end),
        identity_block,
        browser_configure_text,
        flags=re.DOTALL,
    )
else:
    browser_configure_text = browser_configure_text.replace(
        'imply_option("MOZ_APP_VENDOR", "Mozilla")\n',
        identity_block + "\n",
        1,
    )
if identity_start not in browser_configure_text:
    fail("could not set AuRA project identity in browser/moz.configure")
write_if_changed(browser_configure, browser_configure_text)

jar = root / "browser/base/jar.mn"
ensure_line_after_match(
    jar,
    r"content/browser/aboutRobots\.css",
    [
        "        content/browser/aboutAura.html                (content/aboutAura.html)",
        "        content/browser/aboutAura.css                 (content/aboutAura.css)",
        "        content/browser/auraStart.html                (content/auraStart.html)",
        "        content/browser/auraStart.css                 (content/auraStart.css)",
        "        content/browser/auraStart.js                  (content/auraStart.js)",
        "        content/browser/auraStartpageBG.png           (content/auraStartpageBG.png)",
        "        content/browser/auraStartpageLogo.png         (content/auraStartpageLogo.png)",
    ],
)

redirector = root / "browser/components/about/AboutRedirector.cpp"
redirector_text = read(redirector)
if '{"aura",' not in redirector_text:
    aura_entry = (
        '  {"aura", "chrome://browser/content/aboutAura.html",\n'
        '   nsIAboutModule::URI_SAFE_FOR_UNTRUSTED_CONTENT |\n'
        '       nsIAboutModule::URI_CAN_LOAD_IN_CHILD |\n'
        '       nsIAboutModule::MAKE_LINKABLE},\n'
    )
    redirector_text = redirector_text.replace(
        "static const RedirEntry kRedirMap[] = {\n",
        "static const RedirEntry kRedirMap[] = {\n" + aura_entry,
        1,
    )
    if '{"aura",' not in redirector_text:
        fail("could not register about:aura in browser/components/about/AboutRedirector.cpp")
    write_if_changed(redirector, redirector_text)
else:
    print("Already current browser/components/about/AboutRedirector.cpp")

if '{"aurastart",' not in redirector_text:
    aura_start_entry = (
        '  {"aurastart", "chrome://browser/content/auraStart.html",\n'
        '   nsIAboutModule::ALLOW_SCRIPT |\n'
        '       nsIAboutModule::IS_SECURE_CHROME_UI},\n'
    )
    redirector_text = redirector_text.replace(
        "static const RedirEntry kRedirMap[] = {\n",
        "static const RedirEntry kRedirMap[] = {\n" + aura_start_entry,
        1,
    )
    if '{"aurastart",' not in redirector_text:
        fail("could not register about:aurastart in browser/components/about/AboutRedirector.cpp")
    write_if_changed(redirector, redirector_text)
else:
    print("Already current browser/components/about/AboutRedirector.cpp")

components = root / "browser/components/about/components.conf"
components_text = read(components)
missing_about_pages = [
    page
    for page in ["aura", "aurastart"]
    if f"'{page}'," not in components_text and f'"{page}",' not in components_text
]
if missing_about_pages:
    about_page_lines = "".join(f"    '{page}',\n" for page in missing_about_pages)
    components_text = components_text.replace(
        "pages = [\n",
        "pages = [\n" + about_page_lines,
        1,
    )
    for page in missing_about_pages:
        if f"'{page}'," not in components_text:
            fail(f"could not register about:{page} in browser/components/about/components.conf")
    write_if_changed(components, components_text)
else:
    print("Already current browser/components/about/components.conf")

about_new_tab = root / "browser/modules/AboutNewTab.sys.mjs"
about_new_tab_text = read(about_new_tab)
about_new_tab_text = re.sub(
    r'^const ABOUT_URL = "about:(?:newtab|aurastart)";$',
    'const ABOUT_URL = "about:aurastart";',
    about_new_tab_text,
    flags=re.MULTILINE,
)
if 'const ABOUT_URL = "about:aurastart";' not in about_new_tab_text:
    fail("could not set AuRA start page as the default new tab URL in browser/modules/AboutNewTab.sys.mjs")
write_if_changed(about_new_tab, about_new_tab_text)

package_manifest = root / "browser/installer/package-manifest.in"
package_manifest_text = read(package_manifest)
distribution_start = "; >>> AuRA Browser distribution policies\n"
distribution_end = "; <<< AuRA Browser distribution policies"
distribution_block = distribution_start + "@RESPATH@/distribution/*\n" + distribution_end
if distribution_start in package_manifest_text:
    package_manifest_text = re.sub(
        re.escape(distribution_start) + r".*?" + re.escape(distribution_end),
        distribution_block,
        package_manifest_text,
        flags=re.DOTALL,
    )
else:
    existing_distribution_block = "#if defined(BUILT_BY_MOZILLA)\n@RESPATH@/distribution/*"
    if existing_distribution_block in package_manifest_text:
        package_manifest_text = package_manifest_text.replace(
            existing_distribution_block,
            distribution_block + "\n\n" + existing_distribution_block,
            1,
        )
    else:
        package_manifest_text = package_manifest_text.rstrip() + "\n\n" + distribution_block + "\n"
write_if_changed(package_manifest, package_manifest_text)

firefox_js = root / "browser/app/profile/firefox.js"
aura_prefs = read(repo / "overlays/mozilla-central/browser/app/profile/aura.js").strip()
start = "// >>> AuRA Browser defaults\n"
end = "\n// <<< AuRA Browser defaults"
firefox_js_text = read(firefox_js)
block = start + aura_prefs + end
if start in firefox_js_text:
    firefox_js_text = re.sub(
        re.escape(start) + r".*?" + re.escape(end),
        block,
        firefox_js_text,
        flags=re.DOTALL,
    )
else:
    firefox_js_text = firefox_js_text.rstrip() + "\n\n" + block + "\n"
write_if_changed(firefox_js, firefox_js_text)
PY

echo
echo "AuRA Firefox source preparation complete."
echo "Next:"
echo "  ./scripts/build-macos.sh \"$firefox_source\" $config --run --package"
