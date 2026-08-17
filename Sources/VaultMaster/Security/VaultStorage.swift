import Foundation
import CryptoKit

/// 金库安全元数据 (用于存储盐值、密码验证摘要与生物识别配置，无需调用系统钥匙串，避免频繁权限弹窗)
public struct VaultMetadata: Codable, Sendable {
    public var isInitialized: Bool
    public var saltBase64: String
    public var verificationHash: String
    public var biometricsEnabled: Bool
    public var biometricWrappedKeyBase64: String?

    public init(
        isInitialized: Bool = false,
        saltBase64: String = "",
        verificationHash: String = "",
        biometricsEnabled: Bool = false,
        biometricWrappedKeyBase64: String? = nil
    ) {
        self.isInitialized = isInitialized
        self.saltBase64 = saltBase64
        self.verificationHash = verificationHash
        self.biometricsEnabled = biometricsEnabled
        self.biometricWrappedKeyBase64 = biometricWrappedKeyBase64
    }
}

/// 金库数据持久化包结构 (存储于本地文件系统)
public struct VaultDataContainer: Codable, Sendable {
    public var version: Int
    public var items: [VaultItem]
    public var folders: [Folder]
    public var tags: [Tag]
    public var lastSaved: Date

    public init(
        version: Int = 1,
        items: [VaultItem] = [],
        folders: [Folder] = Folder.defaults,
        tags: [Tag] = Tag.defaults,
        lastSaved: Date = Date()
    ) {
        self.version = version
        self.items = items
        self.folders = folders
        self.tags = tags
        self.lastSaved = lastSaved
    }
}

/// 本地安全存储服务
public final class VaultStorage: @unchecked Sendable {
    public static let shared = VaultStorage()

    private var fileManager: FileManager { FileManager.default }
    private let appDirectoryName = "VaultMaster"
    private let vaultFileName = "vault_database.json"
    private let metadataFileName = "vault_metadata.json"

    private init() {}

    /// 获取存储目录 URL
    public var storageDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent(appDirectoryName, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 获取主数据库文件 URL
    public var databaseFileURL: URL {
        storageDirectoryURL.appendingPathComponent(vaultFileName)
    }

    /// 获取元数据配置 URL
    public var metadataFileURL: URL {
        storageDirectoryURL.appendingPathComponent(metadataFileName)
    }

    // MARK: - 元数据操作 (Salt、验证 Hash 与 Touch ID)

    public func loadMetadata() -> VaultMetadata? {
        guard fileManager.fileExists(atPath: metadataFileURL.path),
              let data = try? Data(contentsOf: metadataFileURL) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(VaultMetadata.self, from: data)
    }

    public func saveMetadata(_ metadata: VaultMetadata) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(metadata) {
            try? data.write(to: metadataFileURL, options: .atomic)
        }
    }

    // MARK: - 资产数据库操作

    /// 加载本地数据
    public func loadContainer() -> VaultDataContainer {
        guard fileManager.fileExists(atPath: databaseFileURL.path),
              let data = try? Data(contentsOf: databaseFileURL) else {
            return VaultDataContainer()
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let container = try? decoder.decode(VaultDataContainer.self, from: data) {
            return container
        }
        return VaultDataContainer()
    }

    /// 保存本地数据
    public func saveContainer(_ container: VaultDataContainer) throws {
        var updated = container
        updated.lastSaved = Date()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(updated)
        try data.write(to: databaseFileURL, options: .atomic)
    }

    /// 重置所有本地数据与元数据
    public func resetDatabase() {
        try? fileManager.removeItem(at: databaseFileURL)
        try? fileManager.removeItem(at: metadataFileURL)
    }
}
