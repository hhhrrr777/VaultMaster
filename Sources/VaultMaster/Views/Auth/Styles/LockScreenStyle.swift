import SwiftUI

/// 登录锁屏界面视觉风格枚举
public enum LockScreenStyle: String, CaseIterable, Identifiable, Sendable {
    case glassmorphism = "Apple 极致毛玻璃"
    case cyberTitanium = "钛金极客雷达"
    case elegantStudio = "温润优雅卡片"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .glassmorphism: return "sparkles"
        case .cyberTitanium: return "waveform.path.ecg"
        case .elegantStudio: return "sun.max.fill"
        }
    }
}
