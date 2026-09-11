# VaultMaster 发布指南

## 当前发行状态

现有本机构建为 ad-hoc 临时签名且仅包含 `arm64`，不应作为正式公开版本发送。当前钥匙串中没有可用的 Developer ID Application 身份。正式分发需要 Apple Developer Program、Developer ID Application 证书和 Apple 公证凭据。

## 首次配置公证凭据

安装 Developer ID Application 证书后，将 App Store Connect 专用密码保存到钥匙串（不要写入仓库）：

```bash
xcrun notarytool store-credentials VaultMaster-notary \
  --apple-id "APPLE_ID" \
  --team-id "TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

## 生成正式发行包

```bash
VERSION=1.0.0 \
BUILD_NUMBER=1 \
DEVELOPER_ID_APPLICATION="Developer ID Application: Name (TEAM_ID)" \
NOTARY_PROFILE="VaultMaster-notary" \
./script/package_release.sh
```

脚本会执行 Release 通用架构构建、Hardened Runtime 签名、公证、票据装订、Gatekeeper 验证，并输出：

- `dist/VaultMaster-1.0.0-macOS-universal.zip`
- `dist/VaultMaster-1.0.0-macOS-universal.zip.sha256`
- `dist/VaultMaster-1.0.0-安装说明.md`

如未提供签名身份，脚本只生成明确标记为内部测试用途的 ad-hoc 包，且不会提交公证。

## 发布前检查

```bash
codesign --verify --deep --strict --verbose=2 dist/VaultMaster.app
spctl --assess --type execute --verbose=4 dist/VaultMaster.app
xcrun stapler validate dist/VaultMaster.app
lipo -archs dist/VaultMaster.app/Contents/MacOS/VaultMaster
```

预期架构为 `arm64 x86_64`，Gatekeeper 结果应为 `accepted`，签名应显示 Developer ID 与 Team Identifier。向用户同时提供 ZIP、SHA-256 文件和脚本生成的安装说明。保持 bundle ID `com.antigravity.VaultMaster` 不变，以维持更新和本地数据兼容性。
