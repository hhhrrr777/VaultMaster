import SwiftUI

/// 三栏式左侧侧边栏导航视图
public struct SidebarView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var vaultVM: VaultViewModel

    @State private var showingNewFolderSheet: Bool = false
    @State private var newFolderName: String = ""
    @State private var showingNewTagSheet: Bool = false
    @State private var newTagName: String = ""
    @State private var showingSettingsSheet: Bool = false

    @State private var folderPendingDelete: Folder? = nil
    @State private var tagPendingDelete: Tag? = nil

    public init(appState: AppState, vaultVM: VaultViewModel) {
        self.appState = appState
        self.vaultVM = vaultVM
    }

    public var body: some View {
        List(selection: $appState.selectedFilter) {
            // MARK: - 常用快捷过滤
            Section("常用") {
                NavigationLink(value: SidebarFilter.all) {
                    Label {
                        HStack {
                            Text("全部项目")
                            Spacer()
                            Text("\(vaultVM.count(for: .all))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "tray.full.fill")
                            .foregroundColor(.accentColor)
                    }
                }

                NavigationLink(value: SidebarFilter.favorites) {
                    Label {
                        HStack {
                            Text("个人收藏")
                            Spacer()
                            Text("\(vaultVM.count(for: .favorites))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }

                NavigationLink(value: SidebarFilter.trash) {
                    Label {
                        HStack {
                            Text("废纸篓")
                            Spacer()
                            Text("\(vaultVM.count(for: .trash))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }

            // MARK: - 资产类型库
            Section("资产分类") {
                ForEach(ItemCategory.allCases) { category in
                    NavigationLink(value: SidebarFilter.category(category)) {
                        Label {
                            HStack {
                                Text(category.displayName)
                                Spacer()
                                Text("\(vaultVM.count(for: .category(category)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: category.iconName)
                                .foregroundColor(category.themeColor)
                        }
                    }
                }
            }

            // MARK: - 文件夹
            Section {
                ForEach(vaultVM.folders) { folder in
                    NavigationLink(value: SidebarFilter.folder(folder.id)) {
                        Label {
                            HStack {
                                Text(folder.name)
                                Spacer()
                                Text("\(vaultVM.count(for: .folder(folder.id)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: folder.icon)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            folderPendingDelete = folder
                        } label: {
                            Label("删除文件夹", systemImage: "trash")
                        }
                    }
                }
            } header: {
                HStack {
                    Text("文件夹")
                    Spacer()
                    Button {
                        newFolderName = ""
                        showingNewFolderSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 6)
                    .help("新建文件夹")
                }
            }

            // MARK: - 标签库
            Section {
                ForEach(vaultVM.tags) { tag in
                    NavigationLink(value: SidebarFilter.tag(tag.id)) {
                        Label {
                            HStack {
                                Text(tag.name)
                                Spacer()
                                Text("\(vaultVM.count(for: .tag(tag.id)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            tagPendingDelete = tag
                        } label: {
                            Label("删除标签", systemImage: "trash")
                        }
                    }
                }
            } header: {
                HStack {
                    Text("标签")
                    Spacer()
                    Button {
                        newTagName = ""
                        showingNewTagSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 6)
                    .help("新建标签")
                }
            }
        }
        .listStyle(.sidebar)
        .disableListTypeSelect()
        .frame(minWidth: 200, idealWidth: 220)
        .safeAreaInset(edge: .bottom) {
            bottomControlBar
        }
        // 新建文件夹弹窗
        .alert("新建文件夹", isPresented: $showingNewFolderSheet) {
            TextField("文件夹名称", text: $newFolderName)
            Button("取消", role: .cancel) {}
            Button("创建") {
                if !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    vaultVM.addFolder(name: newFolderName)
                }
            }
        }
        // 新建标签弹窗
        .alert("新建标签", isPresented: $showingNewTagSheet) {
            TextField("标签名称", text: $newTagName)
            Button("取消", role: .cancel) {}
            Button("创建") {
                if !newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    vaultVM.addTag(name: newTagName)
                }
            }
        }
        // 删除文件夹确认弹窗
        .alert(
            "确定要删除文件夹「\(folderPendingDelete?.name ?? "")」吗？",
            isPresented: Binding(
                get: { folderPendingDelete != nil },
                set: { if !$0 { folderPendingDelete = nil } }
            )
        ) {
            Button("取消", role: .cancel) {
                folderPendingDelete = nil
            }
            Button("删除文件夹", role: .destructive) {
                if let folder = folderPendingDelete {
                    vaultVM.deleteFolder(folder)
                    folderPendingDelete = nil
                }
            }
        } message: {
            Text("文件夹被删除后，其中的资产项目仍会保留在金库中，但不再归属于该文件夹。")
        }
        // 删除标签确认弹窗
        .alert(
            "确定要删除标签「\(tagPendingDelete?.name ?? "")」吗？",
            isPresented: Binding(
                get: { tagPendingDelete != nil },
                set: { if !$0 { tagPendingDelete = nil } }
            )
        ) {
            Button("取消", role: .cancel) {
                tagPendingDelete = nil
            }
            Button("删除标签", role: .destructive) {
                if let tag = tagPendingDelete {
                    vaultVM.deleteTag(tag)
                    tagPendingDelete = nil
                }
            }
        } message: {
            Text("标签被删除后，将从所有已关联的资产项目中移除。")
        }
        // 设置弹窗
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsSheetView(appState: appState)
        }
    }

    // MARK: - 侧边栏底部快捷操作栏

    @ViewBuilder
    private var bottomControlBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button {
                    appState.lock()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                        Text("锁定 (⌘L)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    showingSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .help("安全与系统设置")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }
}

/// 设置面板
struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Label("安全与首选项", systemImage: "gearshape.fill")
                    .font(.headline)
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }

            Form {
                Section("安全策略") {
                    Picker("自动锁定时间", selection: $appState.autoLockMinutes) {
                        Text("1 分钟无操作").tag(1)
                        Text("5 分钟无操作").tag(5)
                        Text("15 分钟无操作").tag(15)
                        Text("30 分钟无操作").tag(30)
                        Text("永不自动锁定").tag(0)
                    }

                    Toggle("启用 Touch ID 快速解锁", isOn: $appState.touchIDEnabled)
                }

                Section("关于 VaultMaster") {
                    LabeledContent("版本", value: "1.0.0 (Native Swift)")
                    LabeledContent("加密算法", value: "AES-256-GCM + PBKDF2")
                    LabeledContent("数据存储", value: "本地零知识离线存储")
                }
            }
            .formStyle(.grouped)
        }
        .padding(20)
        .frame(width: 420, height: 340)
    }
}
