#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${CODE_SIGN_IDENTITY:?Set CODE_SIGN_IDENTITY to your Developer ID Application certificate name.}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE to a notarytool keychain profile.}"
if [ "$CODE_SIGN_IDENTITY" = "-" ]; then
    echo "Public notarization requires a Developer ID Application certificate, not ad-hoc signing." >&2
    exit 1
fi
xcrun --find notarytool >/dev/null
xcrun --find stapler >/dev/null
UNIVERSAL=1 bash scripts/build-app.sh
STAGING="$(mktemp -d "${TMPDIR:-/tmp/}NotchPom-notarize.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
APP="$STAGING/NotchPom.app"
ditto --norsrc --noextattr dist/NotchPom.app "$APP"
codesign --verify --deep --strict "$APP"
notarize() {
    xcrun notarytool submit "$1" --keychain-profile "$NOTARY_PROFILE" --wait --output-format json > "$2"
    python3 - "$2" <<'JSONCHECK'
import json, sys
from pathlib import Path
result = json.loads(Path(sys.argv[1]).read_text())
if result.get('status') != 'Accepted':
    sys.exit('Apple did not accept this submission. Review ' + sys.argv[1] + ' and the notarytool log before distributing.')
print('Apple notarization accepted: ' + result['id'])
JSONCHECK
}
ditto -c -k --keepParent "$APP" "$STAGING/submission.zip"
notarize "$STAGING/submission.zip" dist/notarization-app.json
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl --assess --type execute --verbose "$APP"
ditto -c -k --keepParent "$APP" dist/NotchPom-notarized.zip
ln -s /Applications "$STAGING/Applications"
printf 'Drag NotchPom into Applications, eject this disk, then open NotchPom from Applications.\n' > "$STAGING/Install.txt"
rm "$STAGING/submission.zip"
hdiutil create -volname NotchPom -srcfolder "$STAGING" -ov -format UDZO dist/NotchPom-notarized.dmg
codesign --force --timestamp --sign "$CODE_SIGN_IDENTITY" dist/NotchPom-notarized.dmg
notarize dist/NotchPom-notarized.dmg dist/notarization-dmg.json
xcrun stapler staple dist/NotchPom-notarized.dmg
xcrun stapler validate dist/NotchPom-notarized.dmg
spctl --assess --type open --context context:primary-signature --verbose dist/NotchPom-notarized.dmg
(cd dist && shasum -a 256 NotchPom-notarized.dmg NotchPom-notarized.zip > NotchPom-notarized-SHA256SUMS.txt)
echo "Verified notarized downloads are in dist/. Publish only these files."
