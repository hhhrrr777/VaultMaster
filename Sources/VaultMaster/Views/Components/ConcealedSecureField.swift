import SwiftUI
import AppKit

/// 带脱敏显隐与一键复制的密码及敏感信息组件
public struct ConcealedSecureField: View {
    public let title: String
    @Binding public var text: String
    public var placeholder: String = "请输入敏感值"
    public var isEditable: Bool = true
    public var onGeneratePassword: (() -> Void)? = nil

    @State private var isRevealed: Bool = false
    @State private var isCopied: Bool = false

    public init(
        title: String,
        text: Binding<String>,
        placeholder: String = "请输入敏感值",
        isEditable: Bool = true,
        onGeneratePassword: (() -> Void)? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.isEditable = isEditable
        self.onGeneratePassword = onGeneratePassword
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !title.isEmpty {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                Group {
                    if isEditable {
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
                            Text(text.isEmpty ? "（空）" : text)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(text.isEmpty ? .secondary : .primary)
                                .textSelection(.enabled)
                        } else {
                            Text(text.isEmpty ? "（空）" : String(repeating: "•", count: min(max(text.count, 8), 24)))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(text.isEmpty ? .secondary : .primary)
                        }
                        Spacer()
                    }
                }

                HStack(spacing: 6) {
                    // 1. 生成密码快捷按钮 (仅在可编辑且有回调时显示)
                    if isEditable, let generateAction = onGeneratePassword {
                        Button(action: generateAction) {
                            Image(systemName: "dice.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("生成随机强密码")
                    }

                    // 2. 切换显隐按钮
                    Button(action: { isRevealed.toggle() }) {
                        Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(isRevealed ? "隐藏敏感内容" : "显示明文")

                    // 3. 一键复制按钮
                    Button(action: copyToClipboard) {
                        Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                            .font(.system(size: 13))
                            .foregroundColor(isCopied ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(isCopied ? "已复制！" : "复制到剪贴板")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    private func copyToClipboard() {
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isCopied = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.2)) {
                isCopied = false
            }
        }
    }
}
