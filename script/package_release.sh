#!/usr/bin/env bash
set -euo pipefail

APP_NAME="VaultMaster"
BUNDLE_ID="com.antigravity.VaultMaster"
MIN_SYSTEM_VERSION="14.0"
VERSION="${VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
SIGNING_IDENTITY="${DEVELOPER_ID_APPLICATION:--}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ASSET_CATALOG="$ROOT_DIR/Assets/AppIcon.xcassets"
ICON_PARTIAL_PLIST="$DIST_DIR/.AppIcon.partial.plist"
ZIP_NAME="$APP_NAME-$VERSION-macOS-universal.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"
CHECKSUM_PATH="$ZIP_PATH.sha256"
GUIDE_NAME="$APP_NAME-$VERSION-安装说明.md"
GUIDE_PATH="$DIST_DIR/$GUIDE_NAME"
BUILD_ARGS=(-c release --arch arm64 --arch x86_64)

cd "$ROOT_DIR"
swift build "${BUILD_ARGS[@]}"
BUILD_BINARY="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

/usr/bin/xcrun actool "$ASSET_CATALOG" \
  --compile "$APP_RESOURCES" \
  --platform macosx \
  --minimum-deployment-target "$MIN_SYSTEM_VERSION" \
  --app-icon AppIcon \
  --output-partial-info-plist "$ICON_PARTIAL_PLIST" \
  --output-format human-readable-text \
  --warnings \
  --notices
rm -f "$ICON_PARTIAL_PLIST"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIconName</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ "$SIGNING_IDENTITY" == "-" ]]; then
  echo "warning: creating an ad-hoc signed internal test build" >&2
  /usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"
else
  /usr/bin/codesign \
    --force \
    --deep \
    --options runtime \
    --timestamp \
    --sign "$SIGNING_IDENTITY" \
    "$APP_BUNDLE"
fi

/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
rm -f "$ZIP_PATH" "$CHECKSUM_PATH"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

if [[ -n "$NOTARY_PROFILE" ]]; then
  if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    echo "NOTARY_PROFILE requires DEVELOPER_ID_APPLICATION" >&2
    exit 2
  fi
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_BUNDLE"
  xcrun stapler validate "$APP_BUNDLE"
  /usr/sbin/spctl --assess --type execute --verbose=4 "$APP_BUNDLE"
  rm -f "$ZIP_PATH"
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"
fi

(
  cd "$DIST_DIR"
  /usr/bin/shasum -a 256 "$ZIP_NAME" >"$ZIP_NAME.sha256"
)
/bin/cp "$ROOT_DIR/INSTALL.md" "$GUIDE_PATH"

echo "Created $ZIP_PATH"
echo "Created $CHECKSUM_PATH"
echo "Created $GUIDE_PATH"
