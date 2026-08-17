import Foundation
import SwiftUI

/// 资产标签模型
public struct Tag: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var colorHex: String

    public init(id: UUID = UUID(), name: String, colorHex: String = "#FF453A") {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }

    /// 便捷预设标签
    public static let defaults: [Tag] = [
        Tag(name: "重要", colorHex: "#FF453A"),
        Tag(name: "常用", colorHex: "#FF9F0A"),
        Tag(name: "自动续费", colorHex: "#30D158"),
        Tag(name: "生产环境", colorHex: "#BF5AF2")
    ]
}
