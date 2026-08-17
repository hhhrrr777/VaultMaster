import XCTest
import CryptoKit
@testable import VaultMaster

final class CryptoEngineTests: XCTestCase {
    
    var engine: CryptoEngine!
    var sampleKey: SymmetricKey!

    override func setUp() {
        super.setUp()
        engine = CryptoEngine()
        sampleKey = SymmetricKey(size: .bits256)
    }

    func testTextEncryptionAndDecryption() throws {
        let originalText = "MySuperSecretPassword#2026!"
        let ciphertext = try engine.encrypt(text: originalText, using: sampleKey)

        XCTAssertFalse(ciphertext.isEmpty)
        XCTAssertNotEqual(ciphertext, originalText)

        let decrypted = try engine.decrypt(base64Ciphertext: ciphertext, using: sampleKey)
        XCTAssertEqual(decrypted, originalText)
    }

    func testDecryptionWithWrongKeyFails() throws {
        let originalText = "SensitiveDeveloperApiKey_sk_123456789"
        let ciphertext = try engine.encrypt(text: originalText, using: sampleKey)

        let wrongKey = SymmetricKey(size: .bits256)
        XCTAssertThrowsError(try engine.decrypt(base64Ciphertext: ciphertext, using: wrongKey))
    }

    func testEmptyStringEncryption() throws {
        let originalText = ""
        let ciphertext = try engine.encrypt(text: originalText, using: sampleKey)
        let decrypted = try engine.decrypt(base64Ciphertext: ciphertext, using: sampleKey)
        XCTAssertEqual(decrypted, originalText)
    }

    func testSecureRandomBytes() {
        let bytes1 = CryptoEngine.generateSecureRandomBytes(count: 16)
        let bytes2 = CryptoEngine.generateSecureRandomBytes(count: 16)

        XCTAssertEqual(bytes1.count, 16)
        XCTAssertEqual(bytes2.count, 16)
        XCTAssertNotEqual(bytes1, bytes2)
    }
}
