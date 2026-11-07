#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
STAGING="$(mktemp -d "${TMPDIR:-/tmp/}notchpom-build.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
APP="$STAGING/NotchPom.app"
mkdir -p dist
mkdir -p "$APP/Contents/MacOS"
if [ "${UNIVERSAL:-0}" = "1" ]; then
    for ARCH in arm64 x86_64; do
        swift build -c release --arch "$ARCH" --scratch-path ".build/$ARCH" --product NotchPom
    done
    ARM_BIN="$(swift build -c release --arch arm64 --scratch-path .build/arm64 --show-bin-path)"
    INTEL_BIN="$(swift build -c release --arch x86_64 --scratch-path .build/x86_64 --show-bin-path)"
    lipo -create "$ARM_BIN/NotchPom" "$INTEL_BIN/NotchPom" -output "$APP/Contents/MacOS/NotchPom"
else
    swift build -c release --product NotchPom
    BIN_DIR="$(swift build -c release --show-bin-path)"
    cp "$BIN_DIR/NotchPom" "$APP/Contents/MacOS/NotchPom"
fi
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>NotchPom</string>
<key>CFBundleIdentifier</key><string>dev.notchpom.app</string>
<key>CFBundleName</key><string>NotchPom</string>
<key>CFBundleDisplayName</key><string>NotchPom</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.2.0</string>
<key>CFBundleVersion</key><string>2</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrefersDisplaySafeAreaCompatibilityMode</key><false/>
</dict></plist>
PLIST
xattr -cr "$APP"
SIGN_ARGS=(--force --sign "${CODE_SIGN_IDENTITY:--}")
if [ "${CODE_SIGN_IDENTITY:--}" != "-" ]; then
    SIGN_ARGS+=(--options runtime --timestamp)
fi
codesign "${SIGN_ARGS[@]}" "$APP"
codesign --verify --deep --strict "$APP"
ditto --norsrc --noextattr "$APP" dist/NotchPom.app
ditto -c -k --sequesterRsrc --keepParent "$APP" dist/NotchPom.zip
echo "Built $PWD/dist/NotchPom.app"
