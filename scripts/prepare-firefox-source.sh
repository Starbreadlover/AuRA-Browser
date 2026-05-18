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
    if all(line in text for line in new_lines):
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

    lines[insert_at:insert_at] = [line + "\n" for line in new_lines]
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

components = root / "browser/components/about/components.conf"
components_text = read(components)
if "'aura'," not in components_text and '"aura",' not in components_text:
    components_text = components_text.replace(
        "pages = [\n",
        "pages = [\n    'aura',\n",
        1,
    )
    if "'aura'," not in components_text:
        fail("could not register about:aura in browser/components/about/components.conf")
    write_if_changed(components, components_text)
else:
    print("Already current browser/components/about/components.conf")

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
