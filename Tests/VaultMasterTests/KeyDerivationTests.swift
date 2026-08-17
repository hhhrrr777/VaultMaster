import XCTest
import CryptoKit
@testable import VaultMaster

final class KeyDerivationTests: XCTestCase {

    func testPBKDF2DerivationConsistency() throws {
        let password = "UserMasterPassphrase_2026!"
        let salt = KeyDerivation.generateSalt()

        // 相同的密码和盐值派生出的密钥应一致
        let key1 = try KeyDerivation.deriveMasterKey(from: password, salt: salt, rounds: 10_000)
        let key2 = try KeyDerivation.deriveMasterKey(from: password, salt: salt, rounds: 10_000)

        let hash1 = KeyDerivation.computeVerificationHash(masterKey: key1, salt: salt)
        let hash2 = KeyDerivation.computeVerificationHash(masterKey: key2, salt: salt)

        XCTAssertEqual(hash1, hash2)
    }

    func testDifferentSaltsProduceDifferentKeys() throws {
        let password = "UserMasterPassphrase_2026!"
        let salt1 = KeyDerivation.generateSalt()
        let salt2 = KeyDerivation.generateSalt()

        let key1 = try KeyDerivation.deriveMasterKey(from: password, salt: salt1, rounds: 10_000)
        let key2 = try KeyDerivation.deriveMasterKey(from: password, salt: salt2, rounds: 10_000)

        let hash1 = KeyDerivation.computeVerificationHash(masterKey: key1, salt: salt1)
        let hash2 = KeyDerivation.computeVerificationHash(masterKey: key2, salt: salt2)

        XCTAssertNotEqual(hash1, hash2)
    }

    func testEmptyPasswordThrows() {
        let salt = KeyDerivation.generateSalt()
        XCTAssertThrowsError(try KeyDerivation.deriveMasterKey(from: "", salt: salt))
    }
}
