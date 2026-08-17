import Foundation
import LocalAuthentication

/// 生物识别错误类型
public enum BiometricError: LocalizedError, Sendable {
    case notAvailable
    case userCancelled
    case failed(String)
    case passcodeNotSet
    case biometryNotEnrolled

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "当前 Mac 设备不支持 Touch ID 或未启用生物识别"
        case .userCancelled:
            return "用户取消了 Touch ID 验证"
        case .failed(let msg):
            return "Touch ID 验证失败: \(msg)"
        case .passcodeNotSet:
            return "设备尚未设置锁屏密码"
        case .biometryNotEnrolled:
            return "设备尚未录入指纹数据"
        }
    }
}

/// macOS Touch ID / 生物识别认证管理器
@MainActor
public final class BiometricManager: ObservableObject {
    public static let shared = BiometricManager()

    @Published public private(set) var isBiometricsAvailable: Bool = false
    @Published public private(set) var biometryTypeString: String = "Touch ID"

    private init() {
        checkBiometricAvailability()
    }

    /// 检测当前系统是否支持并启用了 Touch ID
    public func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        self.isBiometricsAvailable = canEvaluate

        if #available(macOS 10.15, *) {
            switch context.biometryType {
            case .touchID:
                self.biometryTypeString = "Touch ID"
            case .faceID:
                self.biometryTypeString = "Face ID"
            case .opticID:
                self.biometryTypeString = "Optic ID"
            case .none:
                self.biometryTypeString = "密码解锁"
            @unknown default:
                self.biometryTypeString = "生物识别"
            }
        }
    }

    /// 触发系统 Touch ID 弹窗验证
    /// - Parameter reason: 弹窗提示文案，例如 "使用 Touch ID 解锁 VaultMaster 金库"
    /// - Returns: 验证结果
    public func authenticate(reason: String = "使用 Touch ID 解锁 VaultMaster 金库") async -> Result<Bool, BiometricError> {
        let context = LAContext()
        context.localizedCancelTitle = "使用主密码解锁"
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error as? LAError {
                switch laError.code {
                case .passcodeNotSet:
                    return .failure(.passcodeNotSet)
                case .biometryNotEnrolled:
                    return .failure(.biometryNotEnrolled)
                default:
                    return .failure(.notAvailable)
                }
            }
            return .failure(.notAvailable)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if success {
                return .success(true)
            } else {
                return .failure(.failed("验证未通过"))
            }
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .appCancel:
                return .failure(.userCancelled)
            case .biometryNotAvailable:
                return .failure(.notAvailable)
            case .biometryNotEnrolled:
                return .failure(.biometryNotEnrolled)
            default:
                return .failure(.failed(error.localizedDescription))
            }
        } catch {
            return .failure(.failed(error.localizedDescription))
        }
    }
}
