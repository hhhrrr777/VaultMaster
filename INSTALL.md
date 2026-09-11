# VaultMaster 安装指南

本文面向 VaultMaster 的最终用户。请只从发布者提供的可信渠道获取安装包。

## 系统要求

- macOS 14 Sonoma 或更高版本
- 正式的 Universal 安装包同时支持 Apple Silicon 与 Intel Mac
- Touch ID 为可选功能；没有 Touch ID 仍可使用主密码解锁

## 使用 DMG 拖动安装

1. 如果旧版 VaultMaster 正在运行，先退出应用。
2. 双击 `VaultMaster-<版本>-macOS-universal.dmg`。
3. 将磁盘窗口中的 `VaultMaster.app` 拖到 `Applications` 快捷入口；已有旧版时选择“替换”。
4. 复制完成后，推出“VaultMaster 安装”磁盘。
5. 从 Mac 的“应用程序”文件夹打开 VaultMaster。

替换应用不会删除金库数据。当前本地测试版使用临时签名，尚未经过 Apple 公证；若 macOS 阻止打开，请参阅下方内部测试版说明。

## 安装正式签名版本

1. 下载 `VaultMaster-<版本>-macOS-universal.zip` 和同名 `.sha256` 文件。
2. 可选但推荐：将两个文件放在同一目录，在“终端”执行：

   ```bash
   shasum -a 256 -c VaultMaster-<版本>-macOS-universal.zip.sha256
   ```

   输出 `OK` 表示文件未损坏或被替换。
3. 双击 ZIP 解压，将 `VaultMaster.app` 拖入“应用程序”文件夹。
4. 从“应用程序”打开 VaultMaster。首次启动时设置至少 8 位的主密码，并妥善保存；主密码遗失后无法恢复金库。
5. 根据需要启用 Touch ID。应用不会要求联网，金库数据保存在本机。

## 安装未公证的内部测试版

测试包可能显示“Apple 无法检查其是否包含恶意软件”。仅在你确认文件来自可信发布者时继续：

1. 在 Finder 中按住 Control 点击 `VaultMaster.app`，选择“打开”。
2. 再次点击“打开”。如果没有该选项，进入“系统设置 → 隐私与安全性”，在安全提示旁选择“仍要打开”。

不要使用来源不明的终端命令绕过 macOS 安全检查。公开发布应使用 Developer ID 签名并经过 Apple 公证。

## 更新与卸载

更新前退出 VaultMaster，再用新版应用替换“应用程序”中的旧版本。金库数据位于 `~/Library/Application Support/VaultMaster/`，替换应用不会删除数据。

卸载应用时，将 `VaultMaster.app` 移到废纸篓即可。若需彻底清除数据，请先确认不再需要金库，再删除上述 VaultMaster 数据目录。发布问题时请提供 macOS 版本、Mac 芯片类型和完整错误提示，但不要发送主密码或金库文件。
