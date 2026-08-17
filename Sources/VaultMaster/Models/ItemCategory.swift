import Foundation
import SwiftUI

/// 资产分类枚举与模板定义
public enum ItemCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case login = "login"
    case apiKey = "apiKey"
    case devCredential = "devCredential"
    case paymentCard = "paymentCard"
    case identity = "identity"
    case secureNote = "secureNote"

    public var id: String { rawValue }

    /// 显示名称
    public var displayName: String {
        switch self {
        case .login:
            return "网站与应用"
        case .apiKey:
            return "API Key"
        case .devCredential:
            return "开发凭据"
        case .paymentCard:
            return "银行卡与支付资产"
        case .identity:
            return "个人证件与身份信息"
        case .secureNote:
            return "安全便签"
        }
    }

    /// 简短名称
    public var shortName: String {
        switch self {
        case .login: return "网站/应用"
        case .apiKey: return "API Key"
        case .devCredential: return "开发凭据"
        case .paymentCard: return "银行卡"
        case .identity: return "证件"
        case .secureNote: return "便签"
        }
    }

    /// SF Symbol 图标名称
    public var iconName: String {
        switch self {
        case .login:
            return "globe"
        case .apiKey:
            return "key.fill"
        case .devCredential:
            return "terminal.fill"
        case .paymentCard:
            return "creditcard.fill"
        case .identity:
            return "person.text.rectangle.fill"
        case .secureNote:
            return "note.text"
        }
    }

    /// 分类主题色
    public var themeColor: Color {
        switch self {
        case .login:
            return .blue
        case .apiKey:
            return .orange
        case .devCredential:
            return .indigo
        case .paymentCard:
            return .green
        case .identity:
            return .purple
        case .secureNote:
            return .yellow
        }
    }
}
