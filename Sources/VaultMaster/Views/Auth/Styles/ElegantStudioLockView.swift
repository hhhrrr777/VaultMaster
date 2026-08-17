import SwiftUI

/// 风格三：温润优雅卡片式 (Warm Elegant Studio Card)
public struct ElegantStudioLockView: View {
    @ObservedObject var authVM: AuthViewModel
    var onReset: () -> Void

    @FocusState private var isFocused: Bool

    public init(authVM: AuthViewModel, onReset: @escaping () -> Void) {
        self.authVM = authVM
        self.onReset = onReset
    }

    public var body: some View {
        VStack(spacing: 26) {
            // 1. 温暖头像/徽标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.8), Color.amberGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)
                    .shadow(color: .orange.opacity(0.35), radius: 12, y: 6)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }

            // 2. 问候与标题
            VStack(spacing: 6) {
                Text("欢迎回来")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(.primary)

                Text("输入主密码或使用 Touch ID 解锁您的个人金库")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // 3. 表单卡片
            VStack(spacing: 14) {
                // 密码输入框
                HStack {
                    SecureField("输入主密码...", text: $authVM.passwordInput)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .focused($isFocused)
                        .onSubmit {
                            Task { _ = await authVM.unlockWithPassword() }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    isFocused ? Color.orange.opacity(0.8) : Color.primary.opacity(0.08),
                                    lineWidth: isFocused ? 1.5 : 1
                                )
                        )
                )

                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // 主解锁按钮
                Button {
                    Task { _ = await authVM.unlockWithPassword() }
                } label: {
                    HStack(spacing: 8) {
                        Text("解锁金库")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
                    )
                }
                .buttonStyle(.plain)
                .disabled(authVM.passwordInput.isEmpty || authVM.isAuthenticating)
            }
            .frame(width: 300)

            // 4. Touch ID 快速认证
            Button {
                Task { _ = await authVM.unlockWithBiometrics() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "touchid")
                        .foregroundColor(.orange)
                    Text("使用 Touch ID 快速进入")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            // 5. 底部重置
            Button("忘记主密码？重置金库", action: onReset)
                .font(.caption2)
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
        }
        .padding(36)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 30, y: 10)
        )
        .frame(width: 390)
        .onAppear {
            isFocused = true
        }
    }
}

private extension Color {
    static var amberGradientEnd: Color {
        Color(red: 0.95, green: 0.55, blue: 0.2)
    }
}
