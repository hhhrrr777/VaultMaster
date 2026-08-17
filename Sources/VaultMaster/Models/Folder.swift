import Foundation
import SwiftUI

/// 资产多级文件夹模型
public struct Folder: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var parentId: UUID?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.fill",
        colorHex: String = "#0A84FF",
        parentId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.parentId = parentId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 便捷内置预设文件夹
    public static let defaults: [Folder] = [
        Folder(name: "个人资产", icon: "person.crop.circle.fill", colorHex: "#0A84FF"),
        Folder(name: "工作办公", icon: "briefcase.fill", colorHex: "#FF9F0A"),
        Folder(name: "财务金融", icon: "dollarsign.circle.fill", colorHex: "#30D158"),
        Folder(name: "服务器与开发", icon: "server.rack", colorHex: "#BF5AF2")
    ]
}
