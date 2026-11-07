#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
UNIVERSAL=1 bash scripts/build-app.sh
# Keep signing-sensitive staging outside synced Documents folders, which can
# automatically attach Finder metadata that invalidates strict signature checks.
STAGING="$(mktemp -d "${TMPDIR:-/tmp/}notchpom.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
ditto dist/NotchPom.app "$STAGING/NotchPom.app"
xattr -cr "$STAGING/NotchPom.app"
codesign --verify --deep --strict "$STAGING/NotchPom.app"
ditto -c -k --sequesterRsrc --keepParent "$STAGING/NotchPom.app" dist/NotchPom.zip
ln -s /Applications "$STAGING/Applications"
cp docs/INSTALL.txt "$STAGING/READ ME FIRST.txt"
hdiutil create -volname NotchPom -srcfolder "$STAGING" -ov -format UDZO dist/NotchPom.dmg
(cd dist && shasum -a 256 NotchPom.dmg NotchPom.zip > SHA256SUMS.txt)
echo "Release files: dist/NotchPom.dmg, dist/NotchPom.zip, dist/SHA256SUMS.txt"
