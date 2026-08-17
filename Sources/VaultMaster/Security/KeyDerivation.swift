import Foundation
import CryptoKit
import CommonCrypto

/// 密钥派生与哈希错误
public enum KeyDerivationError: LocalizedError, Sendable {
    case derivationFailed(Int32)
    case invalidSalt
    case emptyPassword

    public var errorDescription: String? {
        switch self {
        case .derivationFailed(let status):
            return "PBKDF2 密钥派生计算失败，系统状态码: \(status)"
        case .invalidSalt:
            return "无效的盐值（Salt）数据"
        case .emptyPassword:
            return "主密码不能为空"
        }
    }
}

/// 强密钥派生服务 (基于 PBKDF2-HMAC-SHA256 / 100,000 轮安全迭代)
/// 负责将用户输入的主密码转换为具备抗暴力破解特性的 256 位加密对称密钥与认证摘要
public enum KeyDerivation {
    
    /// NIST 推荐的安全迭代轮数
    public static let defaultIterations: UInt32 = 100_000
    /// 派生密钥长度（32 字节 = 256 位，用于 AES-256）
    public static let derivedKeyLength: Int = 32
    /// 默认盐值长度（16 字节 = 128 位）
    public static let saltLength: Int = 16

    /// 生成一个密码学安全的随机 Salt
    public static func generateSalt() -> Data {
        CryptoEngine.generateSecureRandomBytes(count: saltLength)
    }

    /// 从用户主密码与 Salt 派生出 256 位的 CryptoKit.SymmetricKey
    /// - Parameters:
    ///   - password: 用户主密码
    ///   - salt: 随机盐值 (16 字节及以上)
    ///   - rounds: 迭代轮数 (默认 100,000)
    /// - Returns: 用于 AES-256-GCM 加解密的主对称密钥
    public static func deriveMasterKey(
        from password: String,
        salt: Data,
        rounds: UInt32 = defaultIterations
    ) throws -> SymmetricKey {
        guard !password.isEmpty else {
            throw KeyDerivationError.emptyPassword
        }
        guard !salt.isEmpty else {
            throw KeyDerivationError.invalidSalt
        }

        let passwordData = Array(password.utf8)
        let saltData = Array(salt)
        var derivedBytes = [UInt8](repeating: 0, count: derivedKeyLength)

        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            password,
            passwordData.count,
            saltData,
            saltData.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            rounds,
            &derivedBytes,
            derivedKeyLength
        )

        guard status == kCCSuccess else {
            throw KeyDerivationError.derivationFailed(status)
        }

        return SymmetricKey(data: Data(derivedBytes))
    }

    /// 计算主密码验证哈希（加盐后进行 SHA-256 计算，用于验证密码正确性，无需持久化明文密码）
    /// - Parameters:
    ///   - masterKey: 派生好的主对称密钥
    ///   - salt: 盐值
    /// - Returns: Base64 编码的验证摘要
    public static func computeVerificationHash(masterKey: SymmetricKey, salt: Data) -> String {
        var hasher = SHA256()
        masterKey.withUnsafeBytes { keyBytes in
            hasher.update(bufferPointer: keyBytes)
        }
        hasher.update(data: salt)
        let digest = hasher.finalize()
        return Data(digest).base64EncodedString()
    }
}
