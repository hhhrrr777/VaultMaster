import XCTest
import CryptoKit
@testable import VaultMaster

final class VaultItemModelTests: XCTestCase {

    var masterKey: SymmetricKey!
    var engine: CryptoEngine!

    override func setUp() {
        super.setUp()
        masterKey = SymmetricKey(size: .bits256)
        engine = CryptoEngine()
    }

    func testEncryptAndDecryptAllCategoryPayloads() throws {
        // 1. 网站登录测试
        var loginItem = VaultItem(title: "Google Account", category: .login)
        var loginPayload = VaultItemPayload(
            username: "alex@gmail.com",
            password: "SuperSecretPassword123!",
            url: "https://accounts.google.com",
            totpSecret: "JBSWY3DPEHPK3PXP",
            notes: "Personal Google Account"
        )
        loginPayload.customFields.append(CustomField(name: "RecoveryEmail", type: .text, value: "backup@example.com"))

        try loginItem.encryptPayload(loginPayload, using: masterKey, engine: engine)
        XCTAssertFalse(loginItem.encryptedPayloadBase64.isEmpty)

        let decryptedLogin = try loginItem.decryptPayload(using: masterKey, engine: engine)
        XCTAssertEqual(decryptedLogin.username, "alex@gmail.com")
        XCTAssertEqual(decryptedLogin.password, "SuperSecretPassword123!")
        XCTAssertEqual(decryptedLogin.url, "https://accounts.google.com")
        XCTAssertEqual(decryptedLogin.customFields.count, 1)
        XCTAssertEqual(decryptedLogin.customFields.first?.value, "backup@example.com")

        // 2. API Key 测试
        var apiKeyItem = VaultItem(title: "OpenAI Secret", category: .apiKey)
        let apiKeyPayload = VaultItemPayload(
            keyId: "org_openai_9988",
            apiKeySecret: "sk-proj-abc123xyz789",
            endpoint: "https://api.openai.com/v1"
        )
        try apiKeyItem.encryptPayload(apiKeyPayload, using: masterKey, engine: engine)
        let decryptedApiKey = try apiKeyItem.decryptPayload(using: masterKey, engine: engine)
        XCTAssertEqual(decryptedApiKey.apiKeySecret, "sk-proj-abc123xyz789")

        // 3. 银行卡测试
        var cardItem = VaultItem(title: "Chase Sapphire", category: .paymentCard)
        let cardPayload = VaultItemPayload(
            cardNumber: "4111222233334444",
            cardholderName: "ALEX SMITH",
            cardType: "Visa",
            expiryDate: "11/29",
            cvv: "123",
            pin: "9876",
            bankName: "Chase Bank"
        )
        try cardItem.encryptPayload(cardPayload, using: masterKey, engine: engine)
        let decryptedCard = try cardItem.decryptPayload(using: masterKey, engine: engine)
        XCTAssertEqual(decryptedCard.cardNumber, "4111222233334444")
        XCTAssertEqual(decryptedCard.cvv, "123")
    }

    func testSubtitlePreviewFormatting() {
        let item1 = VaultItem(title: "My Login", category: .login)
        let payload1 = VaultItemPayload(username: "user@test.com")
        XCTAssertEqual(item1.subtitlePreview(payload: payload1), "user@test.com")

        let item2 = VaultItem(title: "Visa Card", category: .paymentCard)
        let payload2 = VaultItemPayload(cardNumber: "1234567890123456")
        XCTAssertEqual(item2.subtitlePreview(payload: payload2), "•••• •••• •••• 3456")

        let item3 = VaultItem(title: "AWS Key", category: .apiKey)
        let payload3 = VaultItemPayload(keyId: "AKIAIOSFODNN7EXAMPLE")
        XCTAssertEqual(item3.subtitlePreview(payload: payload3), "ID: AKIAIOSFODNN7EXAMPLE")

        let item4 = VaultItem(title: "My Passport", category: .identity)
        let payload4 = VaultItemPayload(fullName: "John Doe")
        XCTAssertEqual(item4.subtitlePreview(payload: payload4), "John Doe")

        let item5 = VaultItem(title: "SSH Note", category: .secureNote)
        let payload5 = VaultItemPayload(notes: "Line 1 note\nLine 2 note")
        XCTAssertEqual(item5.subtitlePreview(payload: payload5), "Line 1 note")
    }
}
