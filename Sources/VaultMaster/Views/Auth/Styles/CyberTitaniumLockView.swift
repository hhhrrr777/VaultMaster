import SwiftUI

/// 风格二：钛金极客雷达风 (Cyber Minimalist Titanium & Radar Pulse)
public struct CyberTitaniumLockView: View {
    @ObservedObject var authVM: AuthViewModel
    var onReset: () -> Void

    @State private var radarRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @FocusState private var isFocused: Bool

    public init(authVM: AuthViewModel, onReset: @escaping () -> Void) {
        self.authVM = authVM
        self.onReset = onReset
    }

    public var body: some View {
        VStack(spacing: 22) {
            // 1. 顶部安全状态灯
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.teal)
                    .frame(width: 7, height: 7)
                    .shadow(color: .teal.opacity(0.8), radius: 4)

                Text("LOCAL HARDWARE ISOLATED • AES-256")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.teal.opacity(0.9))
                    .tracking(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.teal.opacity(0.1))
            .cornerRadius(12)

            // 2. 雷达生物扫描同心圆
            radarBiometricScanner

            // 3. 标题与状态
            VStack(spacing: 4) {
                Text("VAULTMASTER")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(4)

                Text("LOCKED // TAP BIOMETRICS OR ENTER KEY")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .tracking(1.5)
            }

            // 4. 等宽终端输入框
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("$")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.teal)

                    SecureField("ENTER_MASTER_KEY", text: $authVM.passwordInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white)
                        .focused($isFocused)
                        .onSubmit {
                            Task { _ = await authVM.unlockWithPassword() }
                        }

                    Button {
                        Task { _ = await authVM.unlockWithPassword() }
                    } label: {
                        Text("EXEC")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.teal)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .disabled(authVM.passwordInput.isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isFocused ? Color.teal : Color.white.opacity(0.15), lineWidth: 1)
                )

                if let error = authVM.errorMessage {
                    Text("[ERR] \(error)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(width: 320)

            // 5. 底部操作
            HStack(spacing: 16) {
                Button {
                    Task { _ = await authVM.unlockWithBiometrics() }
                } label: {
                    Label("TOUCH ID SCAN", systemImage: "touchid")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.teal)
                }
                .buttonStyle(.plain)

                Spacer()

                Button("RESET_VAULT", action: onReset)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .buttonStyle(.plain)
            }
            .frame(width: 320)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.13, blue: 0.15), Color(red: 0.08, green: 0.09, blue: 0.10)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.6), radius: 30, y: 15)
        )
        .frame(width: 400)
        .onAppear {
            isFocused = true
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                radarRotation = 360
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
        }
    }

    // MARK: - 雷达波纹动画扫描环

    @ViewBuilder
    private var radarBiometricScanner: some View {
        Button {
            Task { _ = await authVM.unlockWithBiometrics() }
        } label: {
            ZStack {
                // 外层雷达同心圆
                Circle()
                    .stroke(Color.teal.opacity(0.2), lineWidth: 1)
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(Color.teal.opacity(0.35), lineWidth: 1)
                    .frame(width: 76, height: 76)

                // 旋转雷达扫描指针
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [.clear, .teal.opacity(0.6)]),
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(radarRotation))

                // 核心指纹图标
                ZStack {
                    Circle()
                        .fill(Color.teal.opacity(0.15))
                        .frame(width: 54, height: 54)
                        .scaleEffect(pulseScale)

                    Image(systemName: "touchid")
                        .font(.system(size: 26))
                        .foregroundColor(.teal)
                }
            }
        }
        .buttonStyle(.plain)
        .help("点击触发 Touch ID 生物识别")
    }
}
