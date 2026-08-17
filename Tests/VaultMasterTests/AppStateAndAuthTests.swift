import XCTest
import CryptoKit
@testable import VaultMaster

@MainActor
final class AppStateAndAuthTests: XCTestCase {

    func testAppStateLockAndUnlock() {
        let appState = AppState.shared
        let key = SymmetricKey(size: .bits256)

        appState.unlock(with: key)
        XCTAssertTrue(appState.isUnlocked)
        XCTAssertNotNil(appState.masterKey)

        appState.lock()
        XCTAssertFalse(appState.isUnlocked)
        XCTAssertNil(appState.masterKey)
        XCTAssertNil(appState.selectedItemId)
    }

    func testAppStateActivityTracking() {
        let appState = AppState.shared
        let before = Date()
        appState.recordUserActivity()
        let after = appState.lastActiveDate

        XCTAssertGreaterThanOrEqual(after.timeIntervalSince1970, before.timeIntervalSince1970 - 0.1)
    }

    func testAuthViewModelValidation() async {
        let authVM = AuthViewModel()

        // 1. 测试空密码
        authVM.passwordInput = ""
        authVM.confirmPasswordInput = ""
        let emptySuccess = await authVM.setupMasterPassword()
        XCTAssertFalse(emptySuccess)
        XCTAssertEqual(authVM.errorMessage, "主密码不能为空")

        // 2. 测试短密码
        authVM.passwordInput = "12345"
        authVM.confirmPasswordInput = "12345"
        let shortSuccess = await authVM.setupMasterPassword()
        XCTAssertFalse(shortSuccess)
        XCTAssertEqual(authVM.errorMessage, "为了您的资产安全，主密码至少需 8 个字符")

        // 3. 测试两次密码不一致
        authVM.passwordInput = "ValidPass2026!"
        authVM.confirmPasswordInput = "DifferentPass2026!"
        let mismatchSuccess = await authVM.setupMasterPassword()
        XCTAssertFalse(mismatchSuccess)
        XCTAssertEqual(authVM.errorMessage, "两次输入的密码不一致")
    }
}
