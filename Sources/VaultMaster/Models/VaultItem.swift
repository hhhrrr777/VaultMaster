import Foundation
import CryptoKit

/// 敏感资产数据载荷 (所有明文敏感信息统一打包，加密后存储为 ciphertext)
public struct VaultItemPayload: Codable, Hashable, Sendable {
    // 1. 网站/应用登录
    public var username: String
    public var email: String
    public var password: String
    public var url: String
    public var totpSecret: String
    public var notes: String

    // 2. API Key
    public var keyId: String
    public var apiKeySecret: String
    public var endpoint: String
    public var customHeaders: String

    // 3. 开发凭据 (SSH Key / 数据库 / 云服务 / Access Token)
    public var credentialType: String
    public var host: String
    public var port: String
    public var privateKeyOrToken: String

    // 4. 银行卡 / 支付资产
    public var cardNumber: String
    public var cardholderName: String
    public var cardType: String
    public var expiryDate: String
    public var cvv: String
    public var pin: String
    public var bankName: String

    // 5. 个人证件与身份信息
    public var idNumber: String
    public var fullName: String
    public var documentType: String
    public var issueDate: String
    public var expirationDate: String
    public var issuingAuthority: String

    // 6. 动态自定义字段
    public var customFields: [CustomField]

    public init(
        username: String = "",
        email: String = "",
        password: String = "",
        url: String = "",
        totpSecret: String = "",
        notes: String = "",
        keyId: String = "",
        apiKeySecret: String = "",
        endpoint: String = "",
        customHeaders: String = "",
        credentialType: String = "",
        host: String = "",
        port: String = "",
        privateKeyOrToken: String = "",
        cardNumber: String = "",
        cardholderName: String = "",
        cardType: String = "",
        expiryDate: String = "",
        cvv: String = "",
        pin: String = "",
        bankName: String = "",
        idNumber: String = "",
        fullName: String = "",
        documentType: String = "",
        issueDate: String = "",
        expirationDate: String = "",
        issuingAuthority: String = "",
        customFields: [CustomField] = []
    ) {
        self.username = username
        self.email = email
        self.password = password
        self.url = url
        self.totpSecret = totpSecret
        self.notes = notes
        self.keyId = keyId
        self.apiKeySecret = apiKeySecret
        self.endpoint = endpoint
        self.customHeaders = customHeaders
        self.credentialType = credentialType
        self.host = host
        self.port = port
        self.privateKeyOrToken = privateKeyOrToken
        self.cardNumber = cardNumber
        self.cardholderName = cardholderName
        self.cardType = cardType
        self.expiryDate = expiryDate
        self.cvv = cvv
        self.pin = pin
        self.bankName = bankName
        self.idNumber = idNumber
        self.fullName = fullName
        self.documentType = documentType
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.issuingAuthority = issuingAuthority
        self.customFields = customFields
    }

    // 处理旧版本 JSON 缺少新增字段的向前兼容解码
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        self.email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        self.password = try container.decodeIfPresent(String.self, forKey: .password) ?? ""
        self.url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
        self.totpSecret = try container.decodeIfPresent(String.self, forKey: .totpSecret) ?? ""
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.keyId = try container.decodeIfPresent(String.self, forKey: .keyId) ?? ""
        self.apiKeySecret = try container.decodeIfPresent(String.self, forKey: .apiKeySecret) ?? ""
        self.endpoint = try container.decodeIfPresent(String.self, forKey: .endpoint) ?? ""
        self.customHeaders = try container.decodeIfPresent(String.self, forKey: .customHeaders) ?? ""
        self.credentialType = try container.decodeIfPresent(String.self, forKey: .credentialType) ?? ""
        self.host = try container.decodeIfPresent(String.self, forKey: .host) ?? ""
        self.port = try container.decodeIfPresent(String.self, forKey: .port) ?? ""
        self.privateKeyOrToken = try container.decodeIfPresent(String.self, forKey: .privateKeyOrToken) ?? ""
        self.cardNumber = try container.decodeIfPresent(String.self, forKey: .cardNumber) ?? ""
        self.cardholderName = try container.decodeIfPresent(String.self, forKey: .cardholderName) ?? ""
        self.cardType = try container.decodeIfPresent(String.self, forKey: .cardType) ?? ""
        self.expiryDate = try container.decodeIfPresent(String.self, forKey: .expiryDate) ?? ""
        self.cvv = try container.decodeIfPresent(String.self, forKey: .cvv) ?? ""
        self.pin = try container.decodeIfPresent(String.self, forKey: .pin) ?? ""
        self.bankName = try container.decodeIfPresent(String.self, forKey: .bankName) ?? ""
        self.idNumber = try container.decodeIfPresent(String.self, forKey: .idNumber) ?? ""
        self.fullName = try container.decodeIfPresent(String.self, forKey: .fullName) ?? ""
        self.documentType = try container.decodeIfPresent(String.self, forKey: .documentType) ?? ""
        self.issueDate = try container.decodeIfPresent(String.self, forKey: .issueDate) ?? ""
        self.expirationDate = try container.decodeIfPresent(String.self, forKey: .expirationDate) ?? ""
        self.issuingAuthority = try container.decodeIfPresent(String.self, forKey: .issuingAuthority) ?? ""
        self.customFields = try container.decodeIfPresent([CustomField].self, forKey: .customFields) ?? []
    }
}

/// 核心资产持久化模型
public struct VaultItem: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var category: ItemCategory
    public var folderId: UUID?
    public var tagIds: [UUID]
    public var isFavorite: Bool
    public var isTrash: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var lastUsedAt: Date?
    /// AES-256-GCM 加密后的 Base64 密文字符串
    public var encryptedPayloadBase64: String

    public init(
        id: UUID = UUID(),
        title: String,
        category: ItemCategory = .login,
        folderId: UUID? = nil,
        tagIds: [UUID] = [],
        isFavorite: Bool = false,
        isTrash: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastUsedAt: Date? = nil,
        encryptedPayloadBase64: String = ""
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.folderId = folderId
        self.tagIds = tagIds
        self.isFavorite = isFavorite
        self.isTrash = isTrash
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsedAt = lastUsedAt
        self.encryptedPayloadBase64 = encryptedPayloadBase64
    }

    // MARK: - 加解密工具方法

    /// 使用主对称密钥加密 Payload 并更新 encryptedPayloadBase64
    public mutating func encryptPayload(_ payload: VaultItemPayload, using masterKey: SymmetricKey, engine: CryptoEngine = CryptoEngine()) throws {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(payload)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw CryptoError.stringConversionFailed
        }
        self.encryptedPayloadBase64 = try engine.encrypt(text: jsonString, using: masterKey)
        self.updatedAt = Date()
    }

    /// 使用主对称密钥解密 encryptedPayloadBase64
    public func decryptPayload(using masterKey: SymmetricKey, engine: CryptoEngine = CryptoEngine()) throws -> VaultItemPayload {
        guard !encryptedPayloadBase64.isEmpty else {
            return VaultItemPayload()
        }
        let decryptedJson = try engine.decrypt(base64Ciphertext: encryptedPayloadBase64, using: masterKey)
        guard let data = decryptedJson.data(using: .utf8) else {
            throw CryptoError.stringConversionFailed
        }
        let decoder = JSONDecoder()
        return try decoder.decode(VaultItemPayload.self, from: data)
    }

    /// 生成列表副标题预览信息
    public func subtitlePreview(payload: VaultItemPayload?) -> String {
        guard let p = payload else {
            return category.displayName
        }
        switch category {
        case .login:
            if !p.username.isEmpty && !p.email.isEmpty { return "\(p.username) (\(p.email))" }
            if !p.username.isEmpty { return p.username }
            if !p.email.isEmpty { return p.email }
            if !p.url.isEmpty { return p.url }
            return "无用户名"
        case .apiKey:
            if !p.keyId.isEmpty { return "ID: \(p.keyId)" }
            if !p.endpoint.isEmpty { return p.endpoint }
            return "API Key"
        case .devCredential:
            if !p.host.isEmpty {
                return p.port.isEmpty ? p.host : "\(p.host):\(p.port)"
            }
            if !p.credentialType.isEmpty { return p.credentialType }
            if !p.username.isEmpty { return p.username }
            return "开发凭据"
        case .paymentCard:
            if p.cardNumber.count >= 4 {
                let suffix = String(p.cardNumber.suffix(4))
                return "•••• •••• •••• \(suffix)"
            }
            return p.bankName.isEmpty ? "银行卡" : p.bankName
        case .identity:
            return p.fullName.isEmpty ? p.documentType : p.fullName
        case .secureNote:
            return p.notes.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines).first ?? "安全便签"
        }
    }
}
