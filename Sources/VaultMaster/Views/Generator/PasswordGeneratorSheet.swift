import SwiftUI
import AppKit

/// 强密码与随机字符串生成器弹窗面板
public struct PasswordGeneratorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = GeneratorViewModel()
    public var onSelectPassword: ((String) -> Void)? = nil

    public init(onSelectPassword: ((String) -> Void)? = nil) {
        self.onSelectPassword = onSelectPassword
    }

    public var body: some View {
        VStack(spacing: 20) {
            // MARK: - 顶部标题与关闭
            HStack {
                Label("强密码生成器", systemImage: "key.fill")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button("关闭") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }

            // MARK: - 密码显示与一键刷新卡片
            VStack(spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    Text(vm.generatedPassword)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)

                    // 重新生成按钮
                    Button {
                        vm.generate()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("重新生成")

                    // 复制按钮
                    Button {
                        vm.copyToClipboard()
                    } label: {
                        Image(systemName: vm.copiedToast ? "checkmark.circle.fill" : "doc.on.doc.fill")
                            .font(.system(size: 14))
                            .foregroundColor(vm.copiedToast ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("复制密码")
                }

                // 强度进度条与评级
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: vm.strength.progress, total: 1.0)
                        .tint(vm.strength.color)
                        .progressViewStyle(.linear)

                    HStack {
                        Text("密码强度：\(vm.strength.title)")
                            .font(.caption)
                            .foregroundColor(vm.strength.color)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(vm.generatedPassword.count) 字符")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )

            // MARK: - 生成模式切换
            Picker("生成模式", selection: $vm.mode) {
                ForEach(GeneratorMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: vm.mode) { _, _ in
                vm.generate()
            }

            // MARK: - 配置选项
            if vm.mode == .randomCharacters {
                randomCharactersOptions
            } else {
                passphraseOptions
            }

            Spacer()

            // MARK: - 底部操作按钮
            HStack(spacing: 12) {
                if let onSelect = onSelectPassword {
                    Button {
                        onSelect(vm.generatedPassword)
                        dismiss()
                    } label: {
                        Text("填入并使用此密码")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button {
                        vm.copyToClipboard()
                        dismiss()
                    } label: {
                        Text("复制并关闭")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .padding(24)
        .frame(width: 440, height: 480)
    }

    // MARK: - 随机字符模式配置项

    @ViewBuilder
    private var randomCharactersOptions: some View {
        VStack(spacing: 12) {
            HStack {
                Text("长度: \(Int(vm.length))")
                    .font(.subheadline)
                    .frame(width: 60, alignment: .leading)
                Slider(value: $vm.length, in: 6...64, step: 1)
                    .onChange(of: vm.length) { _, _ in vm.generate() }
            }

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Toggle("大写字母 (A-Z)", isOn: $vm.includeUppercase)
                        .onChange(of: vm.includeUppercase) { _, _ in vm.generate() }
                    Toggle("小写字母 (a-z)", isOn: $vm.includeLowercase)
                        .onChange(of: vm.includeLowercase) { _, _ in vm.generate() }
                }
                GridRow {
                    Toggle("数字 (0-9)", isOn: $vm.includeNumbers)
                        .onChange(of: vm.includeNumbers) { _, _ in vm.generate() }
                    Toggle("特殊符号 (!@#$)", isOn: $vm.includeSymbols)
                        .onChange(of: vm.includeSymbols) { _, _ in vm.generate() }
                }
                GridRow {
                    Toggle("排除易混淆字符 (1, l, 0, O)", isOn: $vm.excludeAmbiguous)
                        .onChange(of: vm.excludeAmbiguous) { _, _ in vm.generate() }
                }
            }
            .font(.subheadline)
        }
    }

    // MARK: - 密码短语模式配置项

    @ViewBuilder
    private var passphraseOptions: some View {
        VStack(spacing: 12) {
            HStack {
                Text("单词数: \(Int(vm.wordCount))")
                    .font(.subheadline)
                    .frame(width: 70, alignment: .leading)
                Slider(value: $vm.wordCount, in: 3...8, step: 1)
                    .onChange(of: vm.wordCount) { _, _ in vm.generate() }
            }

            HStack {
                Text("分隔符:")
                    .font(.subheadline)
                Picker("", selection: $vm.separator) {
                    Text("连字符 (-)").tag("-")
                    Text("下划线 (_)").tag("_")
                    Text("句点 (.)").tag(".")
                    Text("空格 ( )").tag(" ")
                }
                .labelsHidden()
                .onChange(of: vm.separator) { _, _ in vm.generate() }
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle("单词首字母大写", isOn: $vm.capitalizeWords)
                    .onChange(of: vm.capitalizeWords) { _, _ in vm.generate() }
                Toggle("末尾附加随机数字", isOn: $vm.includeNumberInPassphrase)
                    .onChange(of: vm.includeNumberInPassphrase) { _, _ in vm.generate() }
            }
            .font(.subheadline)
        }
    }
}
