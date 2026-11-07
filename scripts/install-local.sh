#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if pgrep -x NotchPom >/dev/null; then
    echo "Quit NotchPom before installing a replacement." >&2
    exit 1
fi
if [ ! -w /Applications ]; then
    echo "Applications is not writable. Ask your Mac administrator to install this build." >&2
    exit 1
fi
bash scripts/build-app.sh
STAGING="$(mktemp -d /Applications/.NotchPom-install.XXXXXX)"
trap 'rm -rf "$STAGING"' EXIT
ditto --norsrc --noextattr dist/NotchPom.app "$STAGING/NotchPom.app"
codesign --verify --deep --strict "$STAGING/NotchPom.app"
if [ -e /Applications/NotchPom.app ]; then
    BACKUP="dist/local-backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP"
    mv /Applications/NotchPom.app "$BACKUP/NotchPom.app"
    echo "Previous app saved in $PWD/$BACKUP"
fi
mv "$STAGING/NotchPom.app" /Applications/NotchPom.app
open /Applications/NotchPom.app
echo "Installed and opened /Applications/NotchPom.app"
