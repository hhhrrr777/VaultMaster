import SwiftUI

/// 风格一：Apple 极致毛玻璃锁屏界面 (紧凑原生卡片，无多余外围留白)
public struct GlassmorphismLockView: View {
    @ObservedObject var authVM: AuthViewModel
    var onReset: () -> Void

    @State private var isPulsing: Bool = false
    @State private var isTouchIDHovered: Bool = false
    @FocusState private var isFocused: Bool

    public init(authVM: AuthViewModel, onReset: @escaping () -> Void) {
        self.authVM = authVM
        self.onReset = onReset
    }

    public var body: some View {
        ZStack {
            // MARK: - 动态绚丽氛围光斑背景
            ambientGlowBackground

            // MARK: - 登录主体内容 (直接充满视图，布局紧凑精致)
            VStack(spacing: 20) {
                // 1. 发光动态安全盾牌
                glowingShieldBadge
                    .padding(.top, 8)

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

                    Text("硬件级零知识加密已就绪")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // 3. 密码输入与解锁框
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)

                        SecureField("输入主密码解锁...", text: $authVM.passwordInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, design: .monospaced))
                            .focused($isFocused)
                            .onSubmit {
                                Task { _ = await authVM.unlockWithPassword() }
                            }

                        Button {
                            Task { _ = await authVM.unlockWithPassword() }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(authVM.passwordInput.isEmpty ? Color.secondary.opacity(0.15) : Color.blue)
                                    .frame(width: 24, height: 24)

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(authVM.passwordInput.isEmpty ? .secondary : .white)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(authVM.passwordInput.isEmpty || authVM.isAuthenticating)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        isFocused ? Color.blue.opacity(0.6) : Color.white.opacity(0.15),
                                        lineWidth: isFocused ? 1.5 : 1
                                    )
                            )
                    )

                    if let error = authVM.errorMessage {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(.caption2)
                        .foregroundColor(.red)
                        .transition(.opacity)
                    }
                }
                .frame(width: 270)

                // 4. Touch ID 触控解锁按钮（仅在用户主动点击时才触发弹窗）
                Button {
                    Task { _ = await authVM.unlockWithBiometrics() }
                } label: {
                    VStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.blue.opacity(isTouchIDHovered ? 0.3 : 0.15), Color.blue.opacity(0.04)],
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 24
                                    )
                                )
                                .frame(width: 46, height: 46)
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue.opacity(isTouchIDHovered ? 0.5 : 0.2), lineWidth: 1)
                                )

                            Image(systemName: "touchid")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        .scaleEffect(isTouchIDHovered ? 1.06 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTouchIDHovered)

                        Text("Touch ID 快速解锁")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .onHover { isTouchIDHovered = $0 }
                .help("点击使用触控 ID 快速解锁")

                Spacer()

                // 5. 忘记密码 / 重置
                Button("忘记主密码？重置金库", action: onReset)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .buttonStyle(.plain)
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
        }
        .frame(width: 340, height: 420)
        .background(.ultraThinMaterial)
        .onAppear {
            isFocused = true
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    // MARK: - 发光盾牌徽章

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

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - 氛围光斑

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
