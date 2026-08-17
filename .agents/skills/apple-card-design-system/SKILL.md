---
name: apple-card-design-system
description: >-
  Design system and UI component guidelines for VaultMaster based on Apple Human Interface Guidelines
  and macOS Sequoia / Apple Passwords grouped card layouts. Use when building, modifying, or refactoring
  any asset creation, editing, detail, settings, or modal views in VaultMaster.
---

# VaultMaster Apple 原生卡片设计系统规范 (Apple Card Design System)

本规范专用于 **VaultMaster macOS 客户端** 的界面设计与实现，确保全软件所有资产分类（网站/应用、API Key、开发凭据、银行卡、个人证件、安全便签及未来扩展分类）与表单视图保持高度一致、清晰、优雅的原生 macOS 质感。

---

## 1. 核心设计原则 (Core Principles)

1. **分区分组卡片 (Grouped Glass Cards)**:
   - 避免无边界的长列表平铺输入框。
   - 所有逻辑相关字段必须组织在独立的 `AppleCardSection` 中（如「认证凭据」、「连接配置」、「安全校验」、「加密备注」）。
2. **沉浸式 macOS 质感**:
   - 背景采用 `Color(nsColor: .controlBackgroundColor).opacity(0.75)`。
   - 边框采用细微半透明描边 `Color.primary.opacity(0.08)`，圆角 `10pt`（`style: .continuous`）。
   - 卡片间距统一为 `spacing: 16`，内边距 `padding(.horizontal, 14)`，`padding(.vertical, 10)`。
3. **高频操作即时反馈**:
   - 敏感信息支持一键眼睛显隐 (`isPasswordRevealed`)。
   - 关键标识（用户名、URL、Key ID、卡号、证件号）支持一键复制到剪贴板，并带有短时绿色对勾反馈 (`checkmark.circle.fill`)。
   - 密码/私钥字段集成密码强度计算 (`PasswordStrengthCalculator`) 与生成器入口。
   - URL 字段支持有效性检测与一键在系统默认浏览器中打开 (`NSWorkspace.shared.open`)。

---

## 2. 核心通用组件库 (Component Library)

所有通用组件位于 `Sources/VaultMaster/Views/Components/`:

### A. 卡片容器：`AppleCardSection`
```swift
AppleCardSection(title: "基础凭据", icon: "key.fill", iconColor: .orange) {
    CardFieldRow(label: "Key ID", value: $draftPayload.keyId, placeholder: "ak_live_...", isEditing: isEditing)
    CardSecureRow(label: "Secret Key", text: $draftPayload.apiKeySecret, isEditing: isEditing)
}
```

### B. 通用单行字段：`CardFieldRow`
支持只读文本/编辑框自适应、一键复制、URL 打开、邮箱等：
```swift
CardFieldRow(
    label: "接口地址",
    value: $draftPayload.endpoint,
    placeholder: "https://api.openai.com/v1",
    isEditing: isEditing,
    isUrl: true,
    showDivider: false
)
```

### C. 敏感安全信息行：`CardSecureRow`
支持明密文切换、一键复制、可选强密码生成、可选密码强度条：
```swift
CardSecureRow(
    label: "私钥 / Token",
    text: $draftPayload.privateKeyOrToken,
    placeholder: "输入私钥或 Token",
    isEditing: isEditing,
    showStrength: true,
    onGeneratePassword: {
        showingPasswordGenerator = true
    }
)
```

### D. 加密备注卡片：`SecureNotesCardView`
```swift
SecureNotesCardView(notes: $draftPayload.notes, isEditing: isEditing)
```

### E. TOTP 2FA 卡片：`TOTPCardView`
```swift
TOTPCardView(totpSecret: $draftPayload.totpSecret, isEditing: isEditing)
```

---

## 3. 资产分类卡片划分规范 (Asset Categories)

| 分类 | 卡片 1 (核心凭据) | 卡片 2 (扩展属性) | 卡片 3 (安全/其他) | 备注卡片 |
| :--- | :--- | :--- | :--- | :--- |
| **网站与应用 (login)** | 用户名、邮箱、密码(含强度条与生成器) | 关联网址 (含一键打开) | 双重认证 (TOTP 动态码与倒计时环) | 加密备注 |
| **API Key (apiKey)** | Key ID / Client ID, API Secret (含显隐) | 接口 Endpoint (含打开), 自定义 Header | - | 加密备注 |
| **开发凭据 (devCredential)** | 主机/IP, 端口号, 协议类型 | 用户名, 密码/私钥(含显隐与生成器) | - | 加密备注 |
| **银行卡与支付 (paymentCard)** | 持卡人姓名, 银行卡号, 卡片类型, 发卡行 | 有效期 (MM/YY), CVV 安全码, 取款 PIN | - | 加密备注 |
| **个人证件 (identity)** | 真实姓名, 证件类型, 证件号码 | 颁发日期, 过期日期, 签发机关 | - | 加密备注 |
| **安全便签 (secureNote)** | 便签内容 (等宽字体, 自动适应高度) | - | - | - |

---

## 4. 样式 Tokens (Design Tokens)

- **主卡片背景色**: `Color(nsColor: .controlBackgroundColor).opacity(0.75)`
- **卡片边框**: `RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1)`
- **卡片标题字体**: `.font(.system(size: 11, weight: .semibold))` + `.tracking(0.5)`
- **Label 宽度**: 默认 `110pt`，居左对齐，颜色 `.secondary`
- **等宽代码字体**: `.font(.system(.body, design: .monospaced))` (用于密码、Key、TOTP、卡号)
- **分割线规则**: 行间内嵌 `Divider()`，左侧对齐内容起始点（避开 Label 区域）。
