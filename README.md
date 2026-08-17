# VaultMaster - macOS 原生个人本地高安全账户与密码管理系统

**VaultMaster** 是一款专为 macOS 设计的个人本地高安全账户、密码与开发凭据管理桌面软件。完全采用纯原生 Swift 6 与 SwiftUI 开发，遵循 Apple 人机交互指南（HIG），采用零知识加密架构保障您的数字资产安全。

---

## 🌟 核心特性

### 1. 军工级零知识本地加密 (Zero-Knowledge Security)
- **Apple CryptoKit 对称加密**：所有敏感数据在落盘前均通过 **AES-256-GCM** 进行强加密，内存中按需即时解密。
- **PBKDF2 强密钥派生**：通过 100,000 轮安全哈希与随机 Salt 派生 256 位主密钥，杜绝彩虹表与暴力破解。
- **Touch ID / 生物识别解锁**：深度集成 `LocalAuthentication` 框架，支持指纹秒级快速解锁。
- **自动安全锁定**：支持用户自定义无操作超时锁屏（1/5/15/30 分钟），系统休眠及锁屏瞬间自动清理内存并上锁。
- **防窥视脱敏与一键复制**：敏感字段默认星号掩码显示，支持一键切换明文，并配备点击快速复制反馈。

### 2. 五大预置资产模板与动态扩展
- 🌐 **网站与应用登录**：网址 (URL)、用户名/邮箱、密码、2FA/TOTP 密钥、关联文件夹、备注。
- 🔑 **API Key 与开发凭据**：平台名称、Key ID/Client ID、Secret/API Key、Endpoint 接口地址、自定义 Headers。
- 💳 **银行卡与支付资产**：持卡人、卡号、卡类型、有效期、CVV 安全码、取款 PIN 码、发卡银行。
- 🪪 **个人证件与身份信息**：证件类型、姓名、证件号码、颁发日期、有效期、签发机关。
- 📝 **安全便签**：加密 Markdown / 多行文本、SSH 私钥存储。
- ⚙️ **动态自定义字段**：任意资产可随时附加普通文本、隐藏密码、多行文本、日期、开关等字段。
- 📁 **多级文件夹与色彩标签**：支持多维度分类与快速归类检索。

### 3. 生产力与系统级特性
- 🎲 **强密码与 Passphrase 生成器**：支持自定义长度（6-64 位）、字符集过滤、排除易混淆字符、单词短语模式及实时密码熵与强度评分。
- 🖥️ **macOS Menu Bar 状态栏常驻面板**：通过 `MenuBarExtra` 随时从系统菜单栏呼出极速查找和复制账户凭据。
- ⚡ **原生快捷键全面支持**：
  - `⌘ + N`：新建资产
  - `⌘ + F`：聚焦列表搜索
  - `⌘ + L`：立即锁定金库
  - `⌘ + ⌥ + C`：快速复制当前选中条目的密码
  - `⌘ + ⇧ + C`：快速复制当前选中条目的用户名

---

## 🛠️ 项目架构

```
VaultMaster/
├── Package.swift                       // SPM 包配置 (macOS 14.0+)
├── Sources/VaultMaster/
│   ├── App/
│   │   ├── VaultMasterApp.swift        // 应用入口、MenuBarExtra 与生命周期
│   │   └── AppState.swift              // 全局应用状态、锁定状态、活跃检测
│   ├── Models/
│   │   ├── VaultItem.swift             // 核心资产模型与加密载荷封装
│   │   ├── ItemCategory.swift          // 资产分类枚举与模板定义
│   │   ├── CustomField.swift           // 动态自定义字段模型
│   │   ├── Folder.swift                // 文件夹模型
│   │   └── Tag.swift                   // 标签模型
│   ├── Security/
│   │   ├── CryptoEngine.swift          // CryptoKit AES-256-GCM 核心加密引擎
│   │   ├── KeyDerivation.swift         // PBKDF2 强密钥派生服务
│   │   ├── BiometricManager.swift      // Touch ID / 生物识别认证管理器
│   │   ├── KeychainHelper.swift        // 系统钥匙串安全存储辅助类
│   │   └── VaultStorage.swift          // 本地安全持久化存储
│   ├── ViewModels/
│   │   ├── VaultViewModel.swift        // 资产 CRUD、过滤搜索与业务逻辑
│   │   ├── GeneratorViewModel.swift    // 密码生成器逻辑与熵值评分
│   │   └── AuthViewModel.swift         // 主密码设置、认证与解锁流程
│   ├── Views/
│   │   ├── Main/
│   │   │   ├── MainSplitView.swift     // 三栏式主界面容器
│   │   │   ├── SidebarView.swift       // 左侧导航与设置
│   │   │   ├── ItemListView.swift      // 中间搜索与资产列表
│   │   │   └── ItemDetailView.swift    // 右侧详情与表单编辑
│   │   ├── Auth/
│   │   │   ├── SetupMasterPasswordView.swift // 首次主密码初始化
│   │   │   └── LockView.swift          // 金库锁屏界面
│   │   ├── MenuBar/
│   │   │   └── MenuBarPopoverView.swift// 状态栏常驻弹窗
│   │   ├── Generator/
│   │   │   └── PasswordGeneratorSheet.swift // 密码生成器弹窗
│   │   └── Components/
│   │       ├── ConcealedSecureField.swift   // 脱敏与复制组件
│   │       └── CustomFieldEditor.swift      // 自定义字段编辑器
│   └── Utilities/
│       ├── AutoLockMonitor.swift       // 自动锁定与系统休眠监听
│       └── Extensions/
│           └── Color+Hex.swift         // 颜色转换扩展
└── Tests/VaultMasterTests/
    ├── CryptoEngineTests.swift         // 加解密正确性与防篡改测试
    ├── KeyDerivationTests.swift        // 密钥派生与一致性测试
    └── PasswordGeneratorTests.swift    // 密码生成与熵值测试
```

---

## 🚀 编译与运行指南

### 1. 运行单元测试
```bash
swift test
```

### 2. 直接启动调试运行
```bash
swift run VaultMaster
```

### 3. 编译发布版本
```bash
swift build -c release
```

### 4. 在 Xcode 中打开开发
只需在工程目录下执行：
```bash
open Package.swift
```
Xcode 将自动识别并加载所有 SwiftUI 预览、Assets 与完整 macOS Target。

---

## 🔒 隐私与许可
VaultMaster 100% 运行于您的 Mac 本地，不含任何追踪代码，所有敏感数据均受到 macOS 硬件级 Secure Enclave 与 AES-256-GCM 保护。
