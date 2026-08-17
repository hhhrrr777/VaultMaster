import SwiftUI

/// 金库锁屏与解锁主视图 (纯粹紧凑 Apple 极致毛玻璃主体，无多余外围留白)
public struct LockView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var showingResetAlert: Bool = false

    public init(authVM: AuthViewModel) {
        self.authVM = authVM
    }

    public var body: some View {
        GlassmorphismLockView(authVM: authVM) {
            showingResetAlert = true
        }
        .frame(width: 340, height: 420)
        // 彻底移除启动时自动弹窗，只有用户主动点击 Touch ID 按钮时才会触发
        .alert("确定要重置金库吗？", isPresented: $showingResetAlert) {
            Button("取消", role: .cancel) {}
            Button("彻底抹除并重置", role: .destructive) {
                authVM.resetVault()
            }
        } message: {
            Text("此操作将永久抹除所有本地已保存的账号、密码、卡片与加密数据，且不可恢复！")
        }
    }
}
