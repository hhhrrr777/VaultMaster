import Foundation
import Security

/// macOS 系统钥匙串安全存储服务封装
public final class KeychainHelper: Sendable {
    public static let shared = KeychainHelper()
    
    public let service = "com.antigravity.VaultMaster"
    
    // 钥匙串常用 Key 常量
    public enum Keys {
        public static let masterSalt = "vault.master.salt"
        public static let verificationHash = "vault.master.verification_hash"
        public static let biometricMasterKey = "vault.biometric.wrapped_key"
        public static let biometricsEnabled = "vault.biometrics.enabled"
        public static let isVaultInitialized = "vault.initialized"
    }

    private init() {}

    // MARK: - 通用 CRUD 操作

    /// 向 Keychain 写入或更新数据
    @discardableResult
    public func save(key: String, data: Data) -> Bool {
        // 先尝试删除旧数据
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// 从 Keychain 读取数据
    public func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data {
            return data
        }
        return nil
    }

    /// 从 Keychain 删除指定键
    @discardableResult
    public func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - 字符串快捷读写

    @discardableResult
    public func saveString(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(key: key, data: data)
    }

    public func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - 清空金库钥匙串数据

    public func clearAll() {
        delete(key: Keys.masterSalt)
        delete(key: Keys.verificationHash)
        delete(key: Keys.biometricMasterKey)
        delete(key: Keys.biometricsEnabled)
        delete(key: Keys.isVaultInitialized)
    }
}
