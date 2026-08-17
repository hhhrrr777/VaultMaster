import XCTest
@testable import VaultMaster

final class TOTPAndStrengthTests: XCTestCase {

    func testPasswordStrengthCalculatorLevels() {
        let empty = PasswordStrengthCalculator(password: "")
        XCTAssertEqual(empty.level, .veryWeak)

        let weak = PasswordStrengthCalculator(password: "123456")
        XCTAssertEqual(weak.level, .veryWeak)

        let strong = PasswordStrengthCalculator(password: "A8#kL9$zX2!qW8@m")
        XCTAssertEqual(strong.level, .veryStrong)
        XCTAssertGreaterThanOrEqual(strong.entropy, 80)
    }

    func testTOTPGeneratorWithBase32Secret() {
        // 标准 RFC 6238 Base32 测试密钥
        let testSecret = "JBSWY3DPEHPK3PXP"
        let result = TOTPGenerator.generateCurrent(secret: testSecret)
        
        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertEqual(result.code.count, 6)
            XCTAssertEqual(result.formattedCode.count, 7) // 包含中间空格 "123 456"
            XCTAssertGreaterThanOrEqual(result.remainingSeconds, 1)
            XCTAssertLessThanOrEqual(result.remainingSeconds, 30)
            XCTAssertGreaterThanOrEqual(result.progress, 0.0)
            XCTAssertLessThanOrEqual(result.progress, 1.0)
        }
    }

    func testTOTPGeneratorWithOtpauthUri() {
        let otpauth = "otpauth://totp/GitHub:user?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"
        let result = TOTPGenerator.generateCurrent(secret: otpauth)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code.count, 6)
    }

    func testTOTPGeneratorWithInvalidSecret() {
        let invalid = "189!invalid"
        let result = TOTPGenerator.generateCurrent(secret: invalid)
        XCTAssertNil(result)
    }
}
