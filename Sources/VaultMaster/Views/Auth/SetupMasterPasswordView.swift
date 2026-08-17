import SwiftUI

/// 首次启动初始化主密码视图 (与登录锁屏界面 100% 统一的 Apple 极致毛玻璃风格)
public struct SetupMasterPasswordView: View {
    @ObservedObject var authVM: AuthViewModel

    @State private var passwordText: String = ""
    @State private var confirmPasswordText: String = ""
    @State private var isPulsing: Bool = false
    @State private var isConfirmError: Bool = false
    @FocusState private var focusedField: SetupField?

    private enum SetupField {
        case password
        case confirm
    }

    public init(authVM: AuthViewModel) {
        self.authVM = authVM
    }

    public var body: some View {
        ZStack {
            // MARK: - 动态绚丽氛围光斑背景（与登录界面完全一致）
            ambientGlowBackground

            // MARK: - 主体内容
            VStack(spacing: 18) {
                // 1. 发光动态安全盾牌
                glowingShieldBadge
                    .padding(.top, 4)

                // 2. 标题与说明
                VStack(spacing: 4) {
                    Text("VAULTMASTER")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .tracking(3.5)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("设置主密码以创建本地加密金库")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // 3. 表单输入框组
                VStack(spacing: 10) {
                    // 主密码输入框
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)

                        SecureField("设置主密码 (至少 8 位)...", text: $passwordText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, design: .monospaced))
                            .focused($focusedField, equals: .password)
                            .onChange(of: passwordText) { _, newText in
                                authVM.passwordInput = newText
                            }
                            .onSubmit {
                                // 确保主密码不被清空，在下一个 RunLoop 中安全切换焦点，避免 AppKit 取消编辑丢失内容
                                authVM.passwordInput = passwordText
                                DispatchQueue.main.async {
                                    focusedField = .confirm
                                    if confirmPasswordText.isEmpty {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isConfirmError = true
                                        }
                                    }
                                }
                            }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        focusedField == .password ? Color.blue.opacity(0.6) : Color.white.opacity(0.15),
                                        lineWidth: focusedField == .password ? 1.5 : 1
                                    )
                            )
                    )

                    // 确认密码输入框（未输入/不匹配时无文字提示，直接变红框提示）
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isConfirmError ? .red : .secondary)

                        SecureField("再次输入主密码确认...", text: $confirmPasswordText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, design: .monospaced))
                            .focused($focusedField, equals: .confirm)
                            .onChange(of: confirmPasswordText) { _, newText in
                                authVM.confirmPasswordInput = newText
                                if isConfirmError {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        isConfirmError = false
                                    }
                                }
                            }
                            .onSubmit {
                                authVM.confirmPasswordInput = confirmPasswordText
                                DispatchQueue.main.async {
                                    handleSubmit()
                                }
                            }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                isConfirmError
                                    ? Color.red.opacity(0.08)
                                    : Color(nsColor: .controlBackgroundColor).opacity(0.7)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        isConfirmError
                                            ? Color.red.opacity(0.85)
                                            : (focusedField == .confirm ? Color.blue.opacity(0.6) : Color.white.opacity(0.15)),
                                        lineWidth: (isConfirmError || focusedField == .confirm) ? 1.5 : 1
                                    )
                            )
                    )

                    // Touch ID 选项
                    Toggle(isOn: $authVM.enableTouchIDOnSetup) {
                        HStack(spacing: 4) {
                            Image(systemName: "touchid")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            Text("启用 Touch ID 快速解锁")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.checkbox)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }
                .frame(width: 270)

                // 4. 创建并解锁按钮
                Button {
                    handleSubmit()
                } label: {
                    HStack(spacing: 6) {
                        if authVM.isAuthenticating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("创建并开启金库")
                                .font(.system(size: 13, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 270)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.35), radius: 8, y: 3)
                    )
                }
                .buttonStyle(.plain)
                .disabled(passwordText.isEmpty || confirmPasswordText.isEmpty || authVM.isAuthenticating)

                Spacer()

                // 5. 底部安全说明
                Text("零知识本地 AES-256-GCM 保护 • 无云端后门")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
        }
        .frame(width: 340, height: 420)
        .background(.ultraThinMaterial)
        .onAppear {
            passwordText = authVM.passwordInput
            confirmPasswordText = authVM.confirmPasswordInput
            focusedField = .password
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    // MARK: - 提交处理

    private func handleSubmit() {
        authVM.passwordInput = passwordText
        authVM.confirmPasswordInput = confirmPasswordText

        if confirmPasswordText.isEmpty || passwordText != confirmPasswordText {
            withAnimation(.easeInOut(duration: 0.2)) {
                isConfirmError = true
                focusedField = .confirm
            }
            return
        }

        Task {
            _ = await authVM.setupMasterPassword()
        }
    }

    // MARK: - 发光盾牌徽章 (与登录界面完全相同)

    @ViewBuilder
    private var glowingShieldBadge: some View {
        ZStack {
            // 背景光晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.4), Color.cyan.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 42
                    )
                )
                .frame(width: 84, height: 84)
                .scaleEffect(isPulsing ? 1.15 : 0.92)

            // 玻璃质感渐变盾牌
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: .blue.opacity(0.45), radius: 10, y: 5)

                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - 氛围光斑 (与登录界面完全相同)

    @ViewBuilder
    private var ambientGlowBackground: some View {
        ZStack {
            Color.clear

            Circle()
                .fill(Color.blue.opacity(0.16))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .offset(x: -80, y: -70)

            Circle()
                .fill(Color.purple.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 50)
                .offset(x: 80, y: 70)
        }
    }
}
