#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
DESTINATION="$PWD/PulisciTasti.app"
APP="$PWD/.build/staging/PulisciTasti.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" .build/AppIcon.iconset
for arch in arm64 x86_64; do
    xcrun swiftc Sources/main.swift -O -target "$arch-apple-macosx13.0" -o ".build/PulisciTasti-$arch" -framework AppKit -framework SwiftUI -framework ApplicationServices -framework Carbon
done
xcrun lipo -create .build/PulisciTasti-arm64 .build/PulisciTasti-x86_64 -output "$APP/Contents/MacOS/PulisciTasti"
xcrun swift scripts/make-icon.swift "$PWD/.build/AppIcon.iconset"
iconutil -c icns .build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
cp .build/AppIcon.iconset/icon_512x512@2x.png docs/icon.png
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>PulisciTasti</string>
<key>CFBundleIdentifier</key><string>local.nloris.puliscitasti</string>
<key>CFBundleName</key><string>PulisciTasti</string>
<key>CFBundleDisplayName</key><string>PulisciTasti</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.1.1</string>
<key>CFBundleVersion</key><string>3</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSAccessibilityUsageDescription</key><string>Blocca temporaneamente i tasti durante la pulizia. Nessun tasto viene registrato.</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
"$APP/Contents/MacOS/PulisciTasti" --self-test
# Replace the bundle only after successful compilation, signing and self-tests.
# Quit the app before rebuilding; ad-hoc updates may require re-granting Accessibility.
if [[ -d "$DESTINATION" ]]; then
    PREVIOUS="$PWD/.build/PulisciTasti-previous-$(date +%s).app"
    mv "$DESTINATION" "$PREVIOUS"
fi
mv "$APP" "$DESTINATION"
printf 'App pronta: %s\n' "$DESTINATION"
