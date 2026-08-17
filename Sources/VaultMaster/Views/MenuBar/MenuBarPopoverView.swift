import SwiftUI
import AppKit

/// macOS 菜单栏 / Menu Bar 常驻快捷面板视图
public struct MenuBarPopoverView: View {
    @ObservedObject var appState: AppState
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var vaultVM = VaultViewModel()
    @State private var query: String = ""
    @State private var copiedItemId: UUID?

    public init(appState: AppState) {
        self.appState = appState
    }

    private var searchResults: [VaultItem] {
        let all = vaultVM.items.filter { !$0.isTrash }
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // 默认显示收藏或前 6 个条目
            let favorites = all.filter { $0.isFavorite }
            return favorites.isEmpty ? Array(all.prefix(6)) : Array(favorites.prefix(6))
        }
        let q = query.lowercased()
        return all.filter { item in
            if item.title.lowercased().contains(q) { return true }
            let payload = vaultVM.getPayload(for: item)
            return payload.username.lowercased().contains(q) || payload.url.lowercased().contains(q)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            if !appState.isUnlocked {
                lockedStateView
            } else {
                unlockedStateView
            }
        }
        .frame(width: 320, height: 380)
        .background(.ultraThinMaterial)
        .onAppear {
            vaultVM.loadData()
        }
    }

    // MARK: - 锁定状态快捷解锁

    @ViewBuilder
    private var lockedStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 42))
                .foregroundColor(.accentColor)

            Text("VaultMaster 已锁定")
                .font(.headline)

            SecureField("输入主密码解锁", text: $authVM.passwordInput)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 24)
                .onSubmit {
                    Task {
                        _ = await authVM.unlockWithPassword()
                        vaultVM.loadData()
                    }
                }

            HStack(spacing: 12) {
                Button("Touch ID") {
                    Task {
                        _ = await authVM.unlockWithBiometrics()
                        vaultVM.loadData()
                    }
                }
                .buttonStyle(.bordered)

                Button("解锁") {
                    Task {
                        _ = await authVM.unlockWithPassword()
                        vaultVM.loadData()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(authVM.passwordInput.isEmpty)
            }

            Spacer()
        }
    }

    // MARK: - 解锁状态快速查找与复制

    @ViewBuilder
    private var unlockedStateView: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("快速搜索账户或凭据...", text: $query)
                    .textFieldStyle(.plain)
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // 结果列表
            if searchResults.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("无匹配项目")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(searchResults) { item in
                            menuBarItemRow(item: item)
                        }
                    }
                    .padding(6)
                }
            }

            Divider()

            // 底部控制栏
            HStack {
                Button {
                    openMainWindow()
                } label: {
                    Label("打开主窗口", systemImage: "macwindow")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    appState.lock()
                } label: {
                    Label("锁定", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
    }

    // 单元行
    @ViewBuilder
    private func menuBarItemRow(item: VaultItem) -> some View {
        let payload = vaultVM.getPayload(for: item)

        HStack(spacing: 8) {
            Image(systemName: item.category.iconName)
                .font(.system(size: 14))
                .foregroundColor(item.category.themeColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(item.subtitlePreview(payload: payload))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // 快捷复制密码
            let pass = payload.password.isEmpty ? payload.apiKeySecret : payload.password
            if !pass.isEmpty {
                Button {
                    copyValue(pass, itemId: item.id)
                } label: {
                    Image(systemName: copiedItemId == item.id ? "checkmark.circle.fill" : "key.fill")
                        .font(.system(size: 12))
                        .foregroundColor(copiedItemId == item.id ? .green : .accentColor)
                }
                .buttonStyle(.plain)
                .help("复制密码")
            }

            // 快捷复制用户名
            let user = payload.username.isEmpty ? payload.keyId : payload.username
            if !user.isEmpty {
                Button {
                    copyValue(user, itemId: item.id)
                } label: {
                    Image(systemName: "person.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("复制用户名")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        )
    }

    private func copyValue(_ text: String, itemId: UUID) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copiedItemId = itemId
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if self.copiedItemId == itemId {
                self.copiedItemId = nil
            }
        }
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
