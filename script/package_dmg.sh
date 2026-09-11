#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export VERSION="${VERSION:-0.1.1}"
export BUILD_NUMBER="${BUILD_NUMBER:-2}"
"$ROOT_DIR/script/package_release.sh"

DMG_NAME="VaultMaster-$VERSION-macOS-universal.dmg"
STAGING_DIR="$(mktemp -d /tmp/vaultmaster-dmg.XXXXXX)"
/usr/bin/ditto "$ROOT_DIR/dist/VaultMaster.app" "$STAGING_DIR/VaultMaster.app"
ln -s /Applications "$STAGING_DIR/Applications"
cp "$ROOT_DIR/INSTALL.md" "$STAGING_DIR/安装说明.md"
/usr/bin/hdiutil create -volname "VaultMaster 安装" \
  -srcfolder "$STAGING_DIR" -format UDZO -ov \
  "$ROOT_DIR/dist/$DMG_NAME"
/usr/bin/hdiutil verify "$ROOT_DIR/dist/$DMG_NAME"
cd "$ROOT_DIR/dist"
/usr/bin/shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"
echo "Created $ROOT_DIR/dist/$DMG_NAME"
