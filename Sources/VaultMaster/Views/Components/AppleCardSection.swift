import SwiftUI

/// macOS Apple 原生毛玻璃与分组卡片容器
public struct AppleCardSection<Content: View>: View {
    public let title: String
    public var icon: String? = nil
    public var iconColor: Color? = nil
    @ViewBuilder public let content: () -> Content

    public init(
        title: String,
        icon: String? = nil,
        iconColor: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 分区标题
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(iconColor ?? .secondary)
                }
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
            }
            .padding(.leading, 4)

            // 分组卡片主体
            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}

/// 卡片内的标准行容器
public struct AppleCardRow<Content: View>: View {
    public let label: String
    public var labelWidth: CGFloat = 110
    public var showDivider: Bool = true
    @ViewBuilder public let content: () -> Content

    public init(
        label: String,
        labelWidth: CGFloat = 110,
        showDivider: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.label = label
        self.labelWidth = labelWidth
        self.showDivider = showDivider
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: labelWidth, alignment: .leading)
                }

                content()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if showDivider {
                Divider()
                    .padding(.leading, label.isEmpty ? 14 : labelWidth + 26)
            }
        }
    }
}
