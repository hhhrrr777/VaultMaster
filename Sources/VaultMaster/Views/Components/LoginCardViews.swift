import SwiftUI
import AppKit

// MARK: - 1. 账号与密码卡片 (Account & Password Card)

public struct LoginCredentialsCardView: View {
    @Binding public var username: String
    @Binding public var email: String
    @Binding public var password: String
    public let isEditing: Bool
    public var onOpenGenerator: () -> Void

    @State private var isPasswordRevealed: Bool = false
    @State private var isCopiedUsername: Bool = false
    @State private var isCopiedEmail: Bool = false
    @State private var isCopiedPassword: Bool = false

    public init(
        username: Binding<String>,
        email: Binding<String>,
        password: Binding<String>,
        isEditing: Bool,
        onOpenGenerator: @escaping () -> Void
    ) {
        self._username = username
        self._email = email
        self._password = password
        self.isEditing = isEditing
        self.onOpenGenerator = onOpenGenerator
    }

    private var strengthCalc: PasswordStrengthCalculator {
        PasswordStrengthCalculator(password: password)
    }

    public var body: some View {
        AppleCardSection(title: "账号与密码", icon: "person.badge.key.fill", iconColor: .blue) {
            // 用户名行
            AppleCardRow(label: "用户名", showDivider: true) {
                if isEditing {
                    TextField("用户名 / 账号", text: $username)
                        .textFieldStyle(.plain)
                        .font(.body)
                } else {
                    Text(username.isEmpty ? "（未填写）" : username)
                        .font(.body)
                        .foregroundColor(username.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                    Spacer()
                }

                if !username.isEmpty {
                    Button {
                        copyToClipboard(text: username, stateBinding: $isCopiedUsername)
                    } label: {
                        Image(systemName: isCopiedUsername ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(isCopiedUsername ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("复制用户名")
                }
            }

            // 常用邮箱行
            AppleCardRow(label: "电子邮箱", showDivider: true) {
                if isEditing {
                    TextField("user@example.com", text: $email)
                        .textFieldStyle(.plain)
                        .font(.body)
                } else {
                    Text(email.isEmpty ? "（未填写）" : email)
                        .font(.body)
                        .foregroundColor(email.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                    Spacer()
                }

                if !email.isEmpty {
                    Button {
                        copyToClipboard(text: email, stateBinding: $isCopiedEmail)
                    } label: {
                        Image(systemName: isCopiedEmail ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(isCopiedEmail ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("复制邮箱")
                }
            }

            // 登录密码行
            AppleCardRow(label: "登录密码", showDivider: isEditing && !password.isEmpty) {
                Group {
                    if isEditing {
                        if isPasswordRevealed {
                            TextField("输入或生成强密码", text: $password)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("输入或生成强密码", text: $password)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                        }
                    } else {
                        if isPasswordRevealed {
                            Text(password.isEmpty ? "（未设置密码）" : password)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(password.isEmpty ? .secondary : .primary)
                                .textSelection(.enabled)
                        } else {
                            Text(password.isEmpty ? "（未设置密码）" : String(repeating: "•", count: min(max(password.count, 8), 24)))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(password.isEmpty ? .secondary : .primary)
                        }
                        Spacer()
                    }
                }

                HStack(spacing: 8) {
                    // 生成器入口
                    if isEditing {
                        Button {
                            onOpenGenerator()
                        } label: {
                            Label("生成", systemImage: "sparkles")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.12))
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                        .help("打开强密码生成器")
                    }

                    // 显隐按钮
                    if !password.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isPasswordRevealed.toggle()
                            }
                        } label: {
                            Image(systemName: isPasswordRevealed ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(isPasswordRevealed ? "隐藏密码" : "显示明文")

                        // 复制按钮
                        Button {
                            copyToClipboard(text: password, stateBinding: $isCopiedPassword)
                        } label: {
                            Image(systemName: isCopiedPassword ? "checkmark.circle.fill" : "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(isCopiedPassword ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help("复制密码")
                    }
                }
            }

            // 密码强度动态进度条（密码非空时展示）
            if !password.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        // 进度条
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(height: 4)

                                Capsule()
                                    .fill(strengthCalc.level.color)
                                    .frame(width: proxy.size.width * strengthCalc.level.progress, height: 4)
                                    .animation(.easeInOut(duration: 0.25), value: strengthCalc.level.progress)
                            }
                        }
                        .frame(height: 4)

                        Text(strengthCalc.description)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(strengthCalc.level.color)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
                .padding(.top, 2)
            }
        }
    }

    private func copyToClipboard(text: String, stateBinding: Binding<Bool>) {
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        withAnimation(.easeInOut(duration: 0.15)) {
            stateBinding.wrappedValue = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.15)) {
                stateBinding.wrappedValue = false
            }
        }
    }
}

// MARK: - 2. 关联网址卡片 (Web Address Card)

public struct WebAddressCardView: View {
    @Binding public var urlString: String
    public let isEditing: Bool

    @State private var isCopiedUrl: Bool = false

    public init(urlString: Binding<String>, isEditing: Bool) {
        self._urlString = urlString
        self.isEditing = isEditing
    }

    private var isValidUrl: Bool {
        guard let url = URL(string: urlString), let scheme = url.scheme else { return false }
        return scheme == "http" || scheme == "https"
    }

    public var body: some View {
        AppleCardSection(title: "关联网址", icon: "link", iconColor: .teal) {
            AppleCardRow(label: "网址 URL", showDivider: false) {
                if isEditing {
                    TextField("https://example.com/login", text: $urlString)
                        .textFieldStyle(.plain)
                        .font(.body)
                } else {
                    Text(urlString.isEmpty ? "（未填写网址）" : urlString)
                        .font(.body)
                        .foregroundColor(urlString.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                }

                HStack(spacing: 8) {
                    if !urlString.isEmpty {
                        // 复制网址
                        Button {
                            copyUrl()
                        } label: {
                            Image(systemName: isCopiedUrl ? "checkmark.circle.fill" : "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(isCopiedUrl ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help("复制网址")
                    }

                    // 一键打开网址
                    if isValidUrl, let url = URL(string: urlString) {
                        Button {
                            NSWorkspace.shared.open(url)
                        } label: {
                            Label("打开", systemImage: "arrow.up.right.square")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.12))
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                        .help("在默认浏览器中打开")
                    }
                }
            }
        }
    }

    private func copyUrl() {
        guard !urlString.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(urlString, forType: .string)
        withAnimation(.easeInOut(duration: 0.15)) {
            isCopiedUrl = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.15)) {
                isCopiedUrl = false
            }
        }
    }
}

// MARK: - 3. 双重认证 TOTP 卡片 (Two-Factor Authentication Card)

public struct TOTPCardView: View {
    @Binding public var totpSecret: String
    public let isEditing: Bool

    @State private var currentCode: String = ""
    @State private var formattedCode: String = ""
    @State private var remainingSeconds: Int = 30
    @State private var progress: Double = 1.0
    @State private var isCopied: Bool = false
    @State private var isConfiguringSecret: Bool = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(totpSecret: Binding<String>, isEditing: Bool) {
        self._totpSecret = totpSecret
        self.isEditing = isEditing
    }

    public var body: some View {
        AppleCardSection(title: "双重认证 (2FA / TOTP)", icon: "lock.shield.fill", iconColor: .indigo) {
            if !totpSecret.isEmpty, let _ = TOTPGenerator.generateCurrent(secret: totpSecret) {
                // 1. 正常有效 TOTP 动态码展示面板
                VStack(spacing: 12) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("动态验证码")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(formattedCode.isEmpty ? "••• •••" : formattedCode)
                                .font(.system(size: 26, weight: .bold, design: .monospaced))
                                .foregroundColor(.accentColor)
                                .textSelection(.enabled)
                        }

                        Spacer()

                        HStack(spacing: 12) {
                            // 倒计时环
                            ZStack {
                                Circle()
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 3)
                                    .frame(width: 28, height: 28)

                                Circle()
                                    .trim(from: 0.0, to: CGFloat(progress))
                                    .stroke(remainingSeconds <= 5 ? Color.orange : Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 28, height: 28)
                                    .animation(.linear(duration: 1), value: progress)

                                Text("\(remainingSeconds)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(remainingSeconds <= 5 ? .orange : .secondary)
                            }

                            // 复制验证码按钮
                            Button {
                                copyTOTPCode()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    Text(isCopied ? "已复制" : "复制验证码")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(isCopied ? .green : .white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isCopied ? Color.green.opacity(0.15) : Color.accentColor)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // 如果处于编辑模式，允许展开修改密钥
                    if isEditing {
                        Divider()
                        
                        HStack(spacing: 8) {
                            Text("密钥:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("JBSWY3DPEHPK3PXP 或 otpauth://...", text: $totpSecret)
                                .textFieldStyle(.plain)
                                .font(.system(.caption, design: .monospaced))
                            
                            Button("清空") {
                                totpSecret = ""
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .onAppear {
                    refreshTOTP()
                }
                .onReceive(timer) { _ in
                    refreshTOTP()
                }
            } else {
                // 2. 无密钥或密钥无效状态
                if isEditing {
                    AppleCardRow(label: "秘钥 / URL", showDivider: false) {
                        TextField("输入 TOTP Base32 密钥或粘贴 otpauth:// 链接", text: $totpSecret)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                    }
                } else {
                    HStack {
                        Text("未设置双重认证 (2FA)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private func refreshTOTP() {
        guard let info = TOTPGenerator.generateCurrent(secret: totpSecret) else { return }
        self.currentCode = info.code
        self.formattedCode = info.formattedCode
        self.remainingSeconds = info.remainingSeconds
        self.progress = info.progress
    }

    private func copyTOTPCode() {
        guard !currentCode.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentCode, forType: .string)
        withAnimation(.easeInOut(duration: 0.15)) {
            isCopied = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.15)) {
                isCopied = false
            }
        }
    }
}

// MARK: - 4. 加密备注卡片 (Secure Notes Card)

public struct SecureNotesCardView: View {
    @Binding public var notes: String
    public let isEditing: Bool

    public init(notes: Binding<String>, isEditing: Bool) {
        self._notes = notes
        self.isEditing = isEditing
    }

    public var body: some View {
        AppleCardSection(title: "加密备注", icon: "note.text", iconColor: .orange) {
            VStack(alignment: .leading, spacing: 0) {
                if isEditing {
                    TextEditor(text: $notes)
                        .font(.body)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color.clear)
                } else {
                    if notes.isEmpty {
                        Text("（暂无加密备注）")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                    } else {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                    }
                }
            }
        }
    }
}
