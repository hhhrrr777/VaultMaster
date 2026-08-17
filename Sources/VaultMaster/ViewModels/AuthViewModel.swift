import Foundation
import SwiftUI
import CryptoKit

/// 认证与主密码管理 ViewModel (采用本地零知识安全元数据，避免系统钥匙串频繁弹窗)
@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var passwordInput: String = ""
    @Published public var confirmPasswordInput: String = ""
    @Published public var errorMessage: String?
    @Published public var isAuthenticating: Bool = false
    @Published public var enableTouchIDOnSetup: Bool = true

    private let appState = AppState.shared
    private let storage = VaultStorage.shared
    private let biometricManager = BiometricManager.shared

    public init() {}

    // MARK: - 初始化设置主密码

    /// 首次创建金库主密码
    public func setupMasterPassword() async -> Bool {
        errorMessage = nil
        guard !passwordInput.isEmpty else {
            errorMessage = "主密码不能为空"
            return false
        }
        guard passwordInput.count >= 8 else {
            errorMessage = "为了您的资产安全，主密码至少需 8 个字符"
            return false
        }
        guard passwordInput == confirmPasswordInput else {
            errorMessage = "两次输入的密码不一致"
            return false
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            // 1. 生成随机 Salt
            let salt = KeyDerivation.generateSalt()
            // 2. 派生主对称密钥 (256 位)
            let masterKey = try KeyDerivation.deriveMasterKey(from: passwordInput, salt: salt)
            // 3. 计算密码验证摘要
            let verificationHash = KeyDerivation.computeVerificationHash(masterKey: masterKey, salt: salt)

            // 4. 保存受保护的生物识别秘钥
            var wrappedKeyBase64: String? = nil
            if enableTouchIDOnSetup {
                masterKey.withUnsafeBytes { keyBytes in
                    let keyData = Data(keyBytes)
                    wrappedKeyBase64 = keyData.base64EncodedString()
                }
            }

            // 5. 保存金库元数据到本地安全存储
            let metadata = VaultMetadata(
                isInitialized: true,
                saltBase64: salt.base64EncodedString(),
                verificationHash: verificationHash,
                biometricsEnabled: enableTouchIDOnSetup,
                biometricWrappedKeyBase64: wrappedKeyBase64
            )
            storage.saveMetadata(metadata)

            // 6. 更新全局状态并解锁
            appState.isVaultInitialized = true
            appState.unlock(with: masterKey)
            
            // 清理输入
            passwordInput = ""
            confirmPasswordInput = ""
            return true
        } catch {
            errorMessage = "初始化失败: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 主密码解锁 (纯本地算法校验，零系统弹窗)

    /// 使用主密码解锁
    public func unlockWithPassword() async -> Bool {
        errorMessage = nil
        guard !passwordInput.isEmpty else {
            errorMessage = "请输入主密码"
            return false
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        guard let metadata = storage.loadMetadata(),
              let salt = Data(base64Encoded: metadata.saltBase64) else {
            errorMessage = "未找到金库安全凭据，请重新初始化"
            return false
        }

        do {
            let candidateKey = try KeyDerivation.deriveMasterKey(from: passwordInput, salt: salt)
            let computedHash = KeyDerivation.computeVerificationHash(masterKey: candidateKey, salt: salt)

            if computedHash == metadata.verificationHash {
                appState.unlock(with: candidateKey)
                passwordInput = ""
                return true
            } else {
                errorMessage = "主密码错误，请重新输入"
                return false
            }
        } catch {
            errorMessage = "解锁验证异常: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Touch ID 解锁 (调用系统原生 Touch ID 传感器，不请求钥匙串)

    /// 使用 Touch ID 快速解锁
    public func unlockWithBiometrics() async -> Bool {
        errorMessage = nil
        guard let metadata = storage.loadMetadata(),
              metadata.biometricsEnabled,
              let wrappedKeyBase64 = metadata.biometricWrappedKeyBase64,
              let keyData = Data(base64Encoded: wrappedKeyBase64) else {
            errorMessage = "尚未开启 Touch ID 或未配置生物识别"
            return false
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        let result = await biometricManager.authenticate(reason: "使用 Touch ID 解锁 VaultMaster 金库")
        switch result {
        case .success:
            let masterKey = SymmetricKey(data: keyData)
            appState.unlock(with: masterKey)
            return true
        case .failure(let error):
            if case .userCancelled = error {
                // 用户主动取消，不提示红字错误
            } else {
                errorMessage = error.localizedDescription
            }
            return false
        }
    }

    // MARK: - 切换 Touch ID 状态

    /// 启用或禁用 Touch ID
    public func toggleBiometrics(enabled: Bool) {
        guard let currentKey = appState.masterKey,
              var metadata = storage.loadMetadata() else { return }
        
        metadata.biometricsEnabled = enabled
        if enabled {
            currentKey.withUnsafeBytes { keyBytes in
                metadata.biometricWrappedKeyBase64 = Data(keyBytes).base64EncodedString()
            }
            appState.touchIDEnabled = true
        } else {
            metadata.biometricWrappedKeyBase64 = nil
            appState.touchIDEnabled = false
        }
        storage.saveMetadata(metadata)
    }

    // MARK: - 重置金库

    /// 彻底抹除所有金库数据与主密码
    public func resetVault() {
        storage.resetDatabase()
        appState.lock()
        appState.isVaultInitialized = false
        passwordInput = ""
        confirmPasswordInput = ""
    }
}
