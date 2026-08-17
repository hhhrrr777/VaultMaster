import SwiftUI

/// macOS 经典三栏式分栏主容器视图
public struct MainSplitView: View {
    @ObservedObject var appState: AppState
    @StateObject var vaultVM = VaultViewModel()

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        NavigationSplitView {
            SidebarView(appState: appState, vaultVM: vaultVM)
        } content: {
            ItemListView(appState: appState, vaultVM: vaultVM)
        } detail: {
            ItemDetailView(
                itemId: appState.selectedItemId,
                vaultVM: vaultVM,
                appState: appState
            )
        }
        .navigationSplitViewStyle(.balanced)
        .overlay(alignment: .bottom) {
            // Toast 浮动提示
            if let toast = vaultVM.toastMessage {
                Text(toast)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.85))
                            .shadow(radius: 6)
                    )
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            vaultVM.decryptAllItemsIfUnlocked()
        }
        // 键盘快捷键支持
        .background(
            ZStack {
                // ⌘L 锁定金库快捷键
                Button("") {
                    appState.lock()
                }
                .keyboardShortcut("l", modifiers: .command)
                .opacity(0)

                // ⌘C 快速复制当前密码
                Button("") {
                    copySelectedPassword()
                }
                .keyboardShortcut("c", modifiers: [.command, .option])
                .opacity(0)

                // ⌘⇧C 快速复制当前用户名
                Button("") {
                    copySelectedUsername()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .opacity(0)
            }
        )
    }

    private func copySelectedPassword() {
        guard let id = appState.selectedItemId,
              let item = vaultVM.items.first(where: { $0.id == id }) else { return }
        let payload = vaultVM.getPayload(for: item)
        let pass = payload.password.isEmpty ? payload.apiKeySecret : payload.password
        if !pass.isEmpty {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(pass, forType: .string)
        }
    }

    private func copySelectedUsername() {
        guard let id = appState.selectedItemId,
              let item = vaultVM.items.first(where: { $0.id == id }) else { return }
        let payload = vaultVM.getPayload(for: item)
        let user = payload.username.isEmpty ? payload.keyId : payload.username
        if !user.isEmpty {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(user, forType: .string)
        }
    }
}
