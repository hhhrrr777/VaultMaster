import SwiftUI

/// 中间资产列表栏视图
public struct ItemListView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var vaultVM: VaultViewModel
    @State private var showingTrashConfirm: Bool = false
    @State private var itemPendingDelete: VaultItem? = nil

    public init(appState: AppState, vaultVM: VaultViewModel) {
        self.appState = appState
        self.vaultVM = vaultVM
    }

    private var currentFilteredItems: [VaultItem] {
        vaultVM.filteredItems(for: appState.selectedFilter, searchText: appState.searchText)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 废纸篓顶部提醒栏
            if case .trash = appState.selectedFilter {
                trashBanner
            }

            if currentFilteredItems.isEmpty {
                emptyStateView
            } else {
                List(selection: Binding(
                    get: { appState.selectedItemId },
                    set: { newId in
                        if newId != nil {
                            appState.isCreatingNewItem = false
                        }
                        appState.selectedItemId = newId
                    }
                )) {
                    ForEach(currentFilteredItems) { item in
                        ItemRowCard(
                            item: item,
                            payload: vaultVM.getPayload(for: item),
                            tags: vaultVM.tags
                        )
                        .tag(item.id)
                        .contextMenu {
                            contextMenuContent(for: item)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 260, idealWidth: 300)
        .navigationTitle(appState.selectedFilter.title)
        .searchable(text: $appState.searchText, prompt: "搜索标题、用户名、网址、备注...")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // 排序菜单
                Menu {
                    Picker("排序方式", selection: $vaultVM.sortOption) {
                        ForEach(ItemSortOption.allCases) { opt in
                            Text(opt.rawValue).tag(opt)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .help("更改排序")

                // 新建项目菜单 (进入新建草稿表单，点击保存后才真正入库)
                Menu {
                    ForEach(ItemCategory.allCases) { cat in
                        Button {
                            appState.startCreatingItem(category: cat)
                        } label: {
                            Label(cat.displayName, systemImage: cat.iconName)
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .help("新建资产 (⌘N)")
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        // 清空废纸篓确认弹窗
        .alert("确定要清空废纸篓吗？", isPresented: $showingTrashConfirm) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                vaultVM.emptyTrash()
            }
        } message: {
            Text("清空后废纸篓中的所有项目将被永久删除，不可恢复。")
        }
        // 列表右键删除确认弹窗
        .alert(
            itemPendingDelete?.isTrash == true ? "确定要永久删除此项目吗？" : "确定要将此项目移至废纸篓吗？",
            isPresented: Binding(
                get: { itemPendingDelete != nil },
                set: { if !$0 { itemPendingDelete = nil } }
            )
        ) {
            Button("取消", role: .cancel) {
                itemPendingDelete = nil
            }
            Button(itemPendingDelete?.isTrash == true ? "永久删除" : "移至废纸篓", role: .destructive) {
                if let target = itemPendingDelete {
                    if appState.selectedItemId == target.id {
                        appState.selectedItemId = nil
                    }
                    vaultVM.deleteItem(target)
                    itemPendingDelete = nil
                }
            }
        } message: {
            if let target = itemPendingDelete {
                if target.isTrash {
                    Text("此操作将永久抹除「\(target.title)」的所有数据，不可恢复。")
                } else {
                    Text("项目「\(target.title)」将被移至废纸篓，您可以随时在废纸篓中还原或彻底清空。")
                }
            }
        }
    }

    // MARK: - 废纸篓横幅

    @ViewBuilder
    private var trashBanner: some View {
        HStack {
            Image(systemName: "trash.fill")
                .foregroundColor(.secondary)
            Text("废纸篓中的项目可随时还原或彻底清空")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button("清空废纸篓") {
                showingTrashConfirm = true
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        Divider()
    }

    // MARK: - 空状态视图

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.6))
            Text("没有找到相关项目")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("点击右上角「+」或按 ⌘N 录入并新建一个资产条目")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 右键上下文菜单

    @ViewBuilder
    private func contextMenuContent(for item: VaultItem) -> some View {
        let payload = vaultVM.getPayload(for: item)

        if item.isTrash {
            Button {
                vaultVM.restoreItem(item)
            } label: {
                Label("还原此项目", systemImage: "arrow.uturn.backward")
            }

            Button(role: .destructive) {
                itemPendingDelete = item
            } label: {
                Label("永久删除", systemImage: "trash.slash.fill")
            }
        } else {
            // 复制密码
            if !payload.password.isEmpty {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(payload.password, forType: .string)
                } label: {
                    Label("复制密码", systemImage: "key.fill")
                }
            }

            // 复制 API Key
            if !payload.apiKeySecret.isEmpty {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(payload.apiKeySecret, forType: .string)
                } label: {
                    Label("复制 API Key", systemImage: "key.fill")
                }
            }

            // 复制开发凭据 / 私钥 / Token
            if !payload.privateKeyOrToken.isEmpty {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(payload.privateKeyOrToken, forType: .string)
                } label: {
                    Label("复制凭据 / 私钥", systemImage: "terminal.fill")
                }
            }

            // 复制主机地址
            if !payload.host.isEmpty {
                Button {
                    let hostStr = payload.port.isEmpty ? payload.host : "\(payload.host):\(payload.port)"
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(hostStr, forType: .string)
                } label: {
                    Label("复制主机地址", systemImage: "server.rack")
                }
            }

            // 复制用户名
            if !payload.username.isEmpty {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(payload.username, forType: .string)
                } label: {
                    Label("复制用户名", systemImage: "person.fill")
                }
            }

            // 复制邮箱
            if !payload.email.isEmpty {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(payload.email, forType: .string)
                } label: {
                    Label("复制邮箱", systemImage: "envelope.fill")
                }
            }

            Divider()

            // 切换收藏
            Button {
                vaultVM.toggleFavorite(item)
            } label: {
                Label(
                    item.isFavorite ? "取消收藏" : "标为收藏",
                    systemImage: item.isFavorite ? "star.slash" : "star.fill"
                )
            }

            Divider()

            // 删除
            Button(role: .destructive) {
                itemPendingDelete = item
            } label: {
                Label("移至废纸篓", systemImage: "trash")
            }
        }
    }
}

/// 列表卡片单元
struct ItemRowCard: View {
    let item: VaultItem
    let payload: VaultItemPayload
    let tags: [Tag]

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 类型图标
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(item.category.themeColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: item.category.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(item.category.themeColor)
            }

            // 标题与副标题
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                    }
                }

                Text(item.subtitlePreview(payload: payload))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // 标签小圆点
            if !item.tagIds.isEmpty {
                HStack(spacing: 3) {
                    ForEach(item.tagIds.prefix(2), id: \.self) { tagId in
                        if let tag = tags.first(where: { $0.id == tagId }) {
                            Circle()
                                .fill(Color(hex: tag.colorHex) ?? .orange)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
