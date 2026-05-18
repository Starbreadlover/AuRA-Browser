# AuRA Browser branding configuration.
# This file is sourced by Firefox's build system when using:
#   ac_add_options --with-branding=browser/branding/aura

MOZ_APP_NAME=aurabrowser
MOZ_APP_BASENAME=AuRABrowser
MOZ_APP_DISPLAYNAME="AuRA Browser"
MOZ_APP_REMOTINGNAME=aurabrowser
MOZ_MACBUNDLE_ID=io.aura.browser

# Project flags such as MOZ_APP_VENDOR, MOZ_APP_PROFILE, and MOZ_APP_UA_NAME
# are implied from browser/moz.configure by prepare-firefox-source.sh.

# Consider preserving MOZ_APP_ID during early extension compatibility validation.
# Changing it can affect AMO and some extension compatibility assumptions.
