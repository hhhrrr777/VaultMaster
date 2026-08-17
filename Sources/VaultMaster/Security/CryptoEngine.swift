import Foundation
import CryptoKit

/// 安全加密错误类型定义
public enum CryptoError: LocalizedError, Sendable {
    case invalidKeyLength
    case encryptionFailed(String)
    case decryptionFailed(String)
    case invalidCiphertext
    case stringConversionFailed
    case emptyData

    public var errorDescription: String? {
        switch self {
        case .invalidKeyLength:
            return "无效的密钥长度，AES-256 需要 32 字节（256 位）密钥"
        case .encryptionFailed(let reason):
            return "数据加密失败: \(reason)"
        case .decryptionFailed(let reason):
            return "数据解密失败（可能是主密码错误或数据已损坏）: \(reason)"
        case .invalidCiphertext:
            return "无效的密文格式"
        case .stringConversionFailed:
            return "解密后的数据无法转换为 UTF-8 字符串"
        case .emptyData:
            return "待加密数据为空"
        }
    }
}

/// 基于 Apple CryptoKit 的 AES-256-GCM 核心加密引擎
/// 遵循零知识加密原则，所有敏感字段在持久化前加密，仅在内存中按需解密
public final class CryptoEngine: Sendable {
    
    public init() {}
    
    // MARK: - 对称加密 (AES-256-GCM)
    
    /// 加密纯文本字符串为 Base64 编码的综合密文（包含 12 字节 Nonce + 密文主体 + 16 字节 Auth Tag）
    /// - Parameters:
    ///   - plaintext: 待加密明文字符串
    ///   - symmetricKey: 256 位 SymmetricKey
    /// - Returns: Base64 编码的复合密文字符串
    public func encrypt(text plaintext: String, using symmetricKey: SymmetricKey) throws -> String {
        guard let data = plaintext.data(using: .utf8) else {
            throw CryptoError.stringConversionFailed
        }
        let encryptedData = try encrypt(data: data, using: symmetricKey)
        return encryptedData.base64EncodedString()
    }
    
    /// 加密原始二进制数据
    /// - Parameters:
    ///   - data: 待加密数据
    ///   - symmetricKey: 256 位 SymmetricKey
    /// - Returns: 结合了 Nonce、密文与 Auth Tag 的二进制数据
    public func encrypt(data: Data, using symmetricKey: SymmetricKey) throws -> Data {
        do {
            // 使用随机 12 字节 Nonce 进行 AES.GCM 加密
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            guard let combined = sealedBox.combined else {
                throw CryptoError.encryptionFailed("无法生成组合密文")
            }
            return combined
        } catch let error as CryptoError {
            throw error
        } catch {
            throw CryptoError.encryptionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 对称解密 (AES-256-GCM)
    
    /// 解密 Base64 格式的复合密文为纯文本字符串
    /// - Parameters:
    ///   - base64Ciphertext: Base64 编码的密文
    ///   - symmetricKey: 256 位 SymmetricKey
    /// - Returns: 解密后的明文字符串
    public func decrypt(base64Ciphertext: String, using symmetricKey: SymmetricKey) throws -> String {
        guard let data = Data(base64Encoded: base64Ciphertext) else {
            throw CryptoError.invalidCiphertext
        }
        let decryptedData = try decrypt(data: data, using: symmetricKey)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoError.stringConversionFailed
        }
        return string
    }
    
    /// 解密原始二进制复合密文
    /// - Parameters:
    ///   - data: 结合了 Nonce、密文与 Auth Tag 的二进制数据
    ///   - symmetricKey: 256 位 SymmetricKey
    /// - Returns: 解密后的原始数据
    public func decrypt(data: Data, using symmetricKey: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            return decryptedData
        } catch {
            throw CryptoError.decryptionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 辅助校验与随机数生成
    
    /// 生成加密安全的随机字节数组
    /// - Parameter count: 字节数（默认 32 字节）
    /// - Returns: 随机二进制数据
    public static func generateSecureRandomBytes(count: Int = 32) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }
    
    /// 计算 SHA-256 哈希
    public static func sha256(of text: String) -> String {
        guard let data = text.data(using: .utf8) else { return "" }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
