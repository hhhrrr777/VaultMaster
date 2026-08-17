import Foundation
import SwiftUI
import CryptoKit

/// 侧边栏过滤类型
public enum SidebarFilter: Hashable, Sendable {
    case all
    case favorites
    case category(ItemCategory)
    case folder(UUID)
    case tag(UUID)
    case trash

    public var title: String {
        switch self {
        case .all: return "全部项目"
        case .favorites: return "个人收藏"
        case .category(let cat): return cat.displayName
        case .folder: return "文件夹"
        case .tag: return "标签"
        case .trash: return "废纸篓"
        }
    }
}

/// 全局应用状态管理
@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    // MARK: - 解锁与密钥状态
    
    /// 金库是否已解锁
    @Published public var isUnlocked: Bool = false
    /// 金库是否已经初始化设置了主密码
    @Published public var isVaultInitialized: Bool = false
    /// 当前解密的主对称密钥（仅保留在安全内存中，锁定后立即销毁）
    public private(set) var masterKey: SymmetricKey?

    // MARK: - 导航与过滤状态
    
    /// 当前侧边栏选中的过滤器
    @Published public var selectedFilter: SidebarFilter = .all
    /// 当前中间列表选中的资产 ID
    @Published public var selectedItemId: UUID?
    /// 当前搜索关键字
    @Published public var searchText: String = ""

    // MARK: - 新建资产状态
    
    /// 是否处于新建资产表单录入状态（尚未点击保存，不入库）
    @Published public var isCreatingNewItem: Bool = false
    /// 当前新建资产的目标分类
    @Published public var creatingCategory: ItemCategory = .login

    // MARK: - 安全与自动锁定设置
    
    /// 自动锁定超时时间（分钟，0 表示永不）
    @AppStorage("vault.autoLockMinutes") public var autoLockMinutes: Int = 5
    /// 是否开启 Touch ID 解锁
    @AppStorage("vault.touchIDEnabled") public var touchIDEnabled: Bool = true
    /// 最后活跃时间
    public private(set) var lastActiveDate: Date = Date()

    private init() {
        checkInitialization()
    }

    /// 检查金库是否已初始化
    public func checkInitialization() {
        if let metadata = VaultStorage.shared.loadMetadata(), metadata.isInitialized {
            self.isVaultInitialized = true
        } else {
            self.isVaultInitialized = false
        }
    }

    /// 开启新建资产录入流程
    public func startCreatingItem(category: ItemCategory = .login) {
        self.isCreatingNewItem = true
        self.creatingCategory = category
        self.selectedItemId = nil
    }

    /// 取消新建资产
    public func cancelCreatingItem() {
        self.isCreatingNewItem = false
    }

    /// 成功解锁金库
    public func unlock(with key: SymmetricKey) {
        self.masterKey = key
        self.isUnlocked = true
        self.lastActiveDate = Date()
    }

    /// 锁定金库并清空内存中的密钥
    public func lock() {
        self.masterKey = nil
        self.isUnlocked = false
        self.selectedItemId = nil
        self.isCreatingNewItem = false
    }

    /// 刷新用户活跃时间（防误锁定）
    public func recordUserActivity() {
        self.lastActiveDate = Date()
    }
}
