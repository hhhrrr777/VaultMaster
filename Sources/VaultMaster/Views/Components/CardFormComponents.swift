import SwiftUI
import AppKit

// MARK: - 通用表单单行文本字段 (CardFieldRow)

public struct CardFieldRow: View {
    public let label: String
    @Binding public var value: String
    public var placeholder: String = ""
    public let isEditing: Bool
    public var isUrl: Bool = false
    public var isMonospaced: Bool = false
    public var showDivider: Bool = true
    public var labelWidth: CGFloat = 110

    @State private var isCopied: Bool = false

    public init(
        label: String,
        value: Binding<String>,
        placeholder: String = "",
        isEditing: Bool,
        isUrl: Bool = false,
        isMonospaced: Bool = false,
        showDivider: Bool = true,
        labelWidth: CGFloat = 110
    ) {
        self.label = label
        self._value = value
        self.placeholder = placeholder
        self.isEditing = isEditing
        self.isUrl = isUrl
        self.isMonospaced = isMonospaced
        self.showDivider = showDivider
        self.labelWidth = labelWidth
    }

    private var isValidUrl: Bool {
        guard let url = URL(string: value), let scheme = url.scheme else { return false }
        return scheme == "http" || scheme == "https"
    }

    public var body: some View {
        AppleCardRow(label: label, labelWidth: labelWidth, showDivider: showDivider) {
            Group {
                if isEditing {
                    TextField(placeholder.isEmpty ? label : placeholder, text: $value)
                        .textFieldStyle(.plain)
                        .font(isMonospaced ? .system(.body, design: .monospaced) : .body)
                } else {
                    Text(value.isEmpty ? "（未填写）" : value)
                        .font(isMonospaced ? .system(.body, design: .monospaced) : .body)
                        .foregroundColor(value.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                }
            }

            HStack(spacing: 8) {
                // 1. 复制按钮
                if !value.isEmpty {
                    Button {
                        copyToClipboard()
                    } label: {
                        Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(isCopied ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("复制\(label)")
                }

                // 2. 网址一键打开
                if isUrl && isValidUrl, let url = URL(string: value) {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("在浏览器中打开")
                }
            }
        }
    }

    private func copyToClipboard() {
        guard !value.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
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

// MARK: - 通用敏感安全字段 (CardSecureRow)

public struct CardSecureRow: View {
    public let label: String
    @Binding public var text: String
    public var placeholder: String = "请输入敏感值"
    public let isEditing: Bool
    public var showStrength: Bool = false
    public var showDivider: Bool = true
    public var labelWidth: CGFloat = 110
    public var onGeneratePassword: (() -> Void)? = nil

    @State private var isRevealed: Bool = false
    @State private var isCopied: Bool = false

    public init(
        label: String,
        text: Binding<String>,
        placeholder: String = "请输入敏感值",
        isEditing: Bool,
        showStrength: Bool = false,
        showDivider: Bool = true,
        labelWidth: CGFloat = 110,
        onGeneratePassword: (() -> Void)? = nil
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.isEditing = isEditing
        self.showStrength = showStrength
        self.showDivider = showDivider
        self.labelWidth = labelWidth
        self.onGeneratePassword = onGeneratePassword
    }

    private var strengthCalc: PasswordStrengthCalculator {
        PasswordStrengthCalculator(password: text)
    }

    public var body: some View {
        VStack(spacing: 0) {
            AppleCardRow(label: label, labelWidth: labelWidth, showDivider: showDivider && (!showStrength || text.isEmpty)) {
                Group {
                    if isEditing {
                        if isRevealed {
                            TextField(placeholder, text: $text)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField(placeholder, text: $text)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                        }
                    } else {
                        if isRevealed {
                            Text(text.isEmpty ? "（未填写）" : text)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(text.isEmpty ? .secondary : .primary)
                                .textSelection(.enabled)
                        } else {
                            Text(text.isEmpty ? "（未填写）" : String(repeating: "•", count: min(max(text.count, 8), 24)))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(text.isEmpty ? .secondary : .primary)
                        }
                        Spacer()
                    }
                }

                HStack(spacing: 8) {
                    // 1. 生成按钮
                    if isEditing, let generateAction = onGeneratePassword {
                        Button(action: generateAction) {
                            Label("生成", systemImage: "sparkles")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.12))
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                        .help("生成随机强密码")
                    }

                    // 2. 显隐按钮
                    if !text.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isRevealed.toggle()
                            }
                        } label: {
                            Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(isRevealed ? "隐藏敏感内容" : "显示明文")

                        // 3. 复制按钮
                        Button {
                            copyToClipboard()
                        } label: {
                            Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(isCopied ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help("复制内容")
                    }
                }
            }

            // 可选密码强度条
            if showStrength && !text.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
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

                if showDivider {
                    Divider()
                        .padding(.leading, label.isEmpty ? 14 : labelWidth + 26)
                }
            }
        }
    }

    private func copyToClipboard() {
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
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
