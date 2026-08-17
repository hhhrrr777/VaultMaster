import Foundation
import SwiftUI
import CryptoKit

/// 排序选项
public enum ItemSortOption: String, CaseIterable, Identifiable, Sendable {
    case updatedAtDesc = "最近修改"
    case titleAsc = "标题名称 (A-Z)"
    case createdAtDesc = "创建时间"

    public var id: String { rawValue }
}

/// 资产数据与业务逻辑 ViewModel
@MainActor
public final class VaultViewModel: ObservableObject {
    @Published public var items: [VaultItem] = []
    @Published public var folders: [Folder] = []
    @Published public var tags: [Tag] = []
    @Published public var sortOption: ItemSortOption = .updatedAtDesc
    @Published public var toastMessage: String?

    /// 内存中解密后的载荷缓存 (仅在解锁后解密存在于内存中)
    @Published public var decryptedPayloads: [UUID: VaultItemPayload] = [:]

    private let appState = AppState.shared
    private let storage = VaultStorage.shared

    public init() {
        loadData()
    }

    // MARK: - 数据加载与持久化

    /// 从本地加密数据库加载数据
    public func loadData() {
        let container = storage.loadContainer()
        self.items = container.items
        self.folders = container.folders.isEmpty ? Folder.defaults : container.folders
        self.tags = container.tags.isEmpty ? Tag.defaults : container.tags

        // 如果金库已处于解锁状态，预解密所有资产载荷
        if appState.isUnlocked {
            decryptAllPayloads()
        }
    }

    /// 持久化数据到本地文件系统
    public func saveData() {
        let container = VaultDataContainer(
            items: self.items,
            folders: self.folders,
            tags: self.tags
        )
        do {
            try storage.saveContainer(container)
        } catch {
            showToast("数据保存失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 解密管理

    /// 解密所有资产的 Payload
    public func decryptAllPayloads() {
        guard let key = appState.masterKey else { return }
        decryptedPayloads.removeAll()
        for item in items {
            if let payload = try? item.decryptPayload(using: key) {
                decryptedPayloads[item.id] = payload
            }
        }
    }

    /// 兼容调用别名
    public func decryptAllItemsIfUnlocked() {
        decryptAllPayloads()
    }

    /// 获取单个条目的解密 Payload（如果尚未解密则即时解密）
    public func getPayload(for item: VaultItem) -> VaultItemPayload {
        if let payload = decryptedPayloads[item.id] {
            return payload
        }
        if let key = appState.masterKey, let payload = try? item.decryptPayload(using: key) {
            decryptedPayloads[item.id] = payload
            return payload
        }
        return VaultItemPayload()
    }

    // MARK: - 资产 CRUD 操作

    /// 保存或更新资产（自动更新密文并落盘）
    public func saveItem(item: inout VaultItem, payload: VaultItemPayload) {
        guard let key = appState.masterKey else {
            showToast("金库已锁定，无法保存")
            return
        }

        do {
            try item.encryptPayload(payload, using: key)
            item.updatedAt = Date()

            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = item
            } else {
                items.insert(item, at: 0)
            }

            decryptedPayloads[item.id] = payload
            saveData()
            showToast("已安全保存")
        } catch {
            showToast("加密保存失败: \(error.localizedDescription)")
        }
    }

    /// 移入废纸篓或永久删除
    public func deleteItem(_ item: VaultItem) {
        if item.isTrash {
            // 彻底物理删除
            items.removeAll(where: { $0.id == item.id })
            decryptedPayloads.removeValue(forKey: item.id)
            saveData()
            showToast("已永久删除")
        } else {
            // 移入废纸篓
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index].isTrash = true
                items[index].updatedAt = Date()
                saveData()
                showToast("已移至废纸篓")
            }
        }
    }

    /// 从废纸篓还原
    public func restoreItem(_ item: VaultItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isTrash = false
            items[index].updatedAt = Date()
            saveData()
            showToast("已还原资产")
        }
    }

    /// 清空废纸篓
    public func emptyTrash() {
        let trashIds = items.filter { $0.isTrash }.map { $0.id }
        items.removeAll(where: { $0.isTrash })
        for id in trashIds {
            decryptedPayloads.removeValue(forKey: id)
        }
        saveData()
        showToast("废纸篓已清空")
    }

    /// 切换收藏状态
    public func toggleFavorite(_ item: VaultItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isFavorite.toggle()
            items[index].updatedAt = Date()
            saveData()
        }
    }

    // MARK: - 文件夹与标签管理

    @discardableResult
    public func addFolder(name: String, icon: String = "folder.fill", colorHex: String = "#0A84FF") -> Folder {
        let folder = Folder(name: name, icon: icon, colorHex: colorHex)
        folders.append(folder)
        saveData()
        return folder
    }

    public func deleteFolder(_ folder: Folder) {
        folders.removeAll(where: { $0.id == folder.id })
        for i in 0..<items.count {
            if items[i].folderId == folder.id {
                items[i].folderId = nil
            }
        }
        saveData()
    }

    @discardableResult
    public func addTag(name: String, colorHex: String = "#FF453A") -> Tag {
        // 如果已存在同名标签直接返回已有的
        if let existing = tags.first(where: { $0.name == name }) {
            return existing
        }
        let tag = Tag(name: name, colorHex: colorHex)
        tags.append(tag)
        saveData()
        return tag
    }

    public func deleteTag(_ tag: Tag) {
        tags.removeAll(where: { $0.id == tag.id })
        for i in 0..<items.count {
            items[i].tagIds.removeAll(where: { $0 == tag.id })
        }
        saveData()
    }

    // MARK: - 过滤与搜索计算属性

    /// 根据侧边栏选中的 Filter 与搜索框过滤出目标列表
    public func filteredItems(for filter: SidebarFilter, searchText: String) -> [VaultItem] {
        var result = items

        // 1. 过滤废纸篓与基础分类
        switch filter {
        case .all:
            result = result.filter { !$0.isTrash }
        case .favorites:
            result = result.filter { !$0.isTrash && $0.isFavorite }
        case .category(let category):
            result = result.filter { !$0.isTrash && $0.category == category }
        case .folder(let folderId):
            result = result.filter { !$0.isTrash && $0.folderId == folderId }
        case .tag(let tagId):
            result = result.filter { !$0.isTrash && $0.tagIds.contains(tagId) }
        case .trash:
            result = result.filter { $0.isTrash }
        }

        // 2. 搜索框文本匹配 (匹配标题、用户名、URL、备注等)
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            result = result.filter { item in
                if item.title.lowercased().contains(query) { return true }
                if let payload = decryptedPayloads[item.id] {
                    if payload.username.lowercased().contains(query) { return true }
                    if payload.url.lowercased().contains(query) { return true }
                    if payload.notes.lowercased().contains(query) { return true }
                    if payload.keyId.lowercased().contains(query) { return true }
                    if payload.cardholderName.lowercased().contains(query) { return true }
                    if payload.fullName.lowercased().contains(query) { return true }
                }
                return false
            }
        }

        // 3. 排序
        switch sortOption {
        case .updatedAtDesc:
            result.sort { $0.updatedAt > $1.updatedAt }
        case .titleAsc:
            result.sort { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .createdAtDesc:
            result.sort { $0.createdAt > $1.createdAt }
        }

        return result
    }

    /// 统计指定 Filter 下的项目总数
    public func count(for filter: SidebarFilter) -> Int {
        switch filter {
        case .all:
            return items.filter { !$0.isTrash }.count
        case .favorites:
            return items.filter { !$0.isTrash && $0.isFavorite }.count
        case .category(let cat):
            return items.filter { !$0.isTrash && $0.category == cat }.count
        case .folder(let folderId):
            return items.filter { !$0.isTrash && $0.folderId == folderId }.count
        case .tag(let tagId):
            return items.filter { !$0.isTrash && $0.tagIds.contains(tagId) }.count
        case .trash:
            return items.filter { $0.isTrash }.count
        }
    }

    // MARK: - Toast 提示

    private func showToast(_ msg: String) {
        self.toastMessage = msg
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if self.toastMessage == msg {
                self.toastMessage = nil
            }
        }
    }
}
