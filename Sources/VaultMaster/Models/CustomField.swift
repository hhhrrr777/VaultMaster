import Foundation
import SwiftUI

/// 动态自定义字段类型
public enum CustomFieldType: String, Codable, CaseIterable, Identifiable, Sendable {
    case text = "text"
    case concealed = "concealed"
    case multiline = "multiline"
    case date = "date"
    case boolean = "boolean"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .text:
            return "普通文本"
        case .concealed:
            return "隐藏/敏感密码"
        case .multiline:
            return "多行文本"
        case .date:
            return "日期"
        case .boolean:
            return "开关状态"
        }
    }

    public var iconName: String {
        switch self {
        case .text:
            return "textformat"
        case .concealed:
            return "eye.slash.fill"
        case .multiline:
            return "text.alignleft"
        case .date:
            return "calendar"
        case .boolean:
            return "switch.2"
        }
    }
}

/// 动态自定义字段实体
public struct CustomField: Codable, Identifiable, Hashable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var type: CustomFieldType
    public var value: String

    public init(id: UUID = UUID(), name: String, type: CustomFieldType, value: String = "") {
        self.id = id
        self.name = name
        self.type = type
        self.value = value
    }
}
