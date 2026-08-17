import SwiftUI

/// 可搜索多选标签下拉组件 (Searchable Multi-Select Tag Picker)
public struct TagSelectorView: View {
    @Binding public var selectedTagIds: [UUID]
    public let allTags: [Tag]
    public var isEditable: Bool
    public var onAddTag: ((String, String) -> Tag)?

    @State private var showingTagPopover: Bool = false
    @State private var searchText: String = ""
    @State private var showingNewTagAlert: Bool = false
    @State private var newTagName: String = ""
    @State private var newTagColorHex: String = "#FF9F0A"

    private let presetColors: [String] = [
        "#FF453A", "#FF9F0A", "#FFD60A", "#30D158",
        "#66D4CF", "#40C8E0", "#0A84FF", "#5E5CE6",
        "#BF5AF2", "#FF375F", "#AC8E68", "#98989D"
    ]

    public init(
        selectedTagIds: Binding<[UUID]>,
        allTags: [Tag],
        isEditable: Bool,
        onAddTag: ((String, String) -> Tag)? = nil
    ) {
        self._selectedTagIds = selectedTagIds
        self.allTags = allTags
        self.isEditable = isEditable
        self.onAddTag = onAddTag
    }

    private var filteredTags: [Tag] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return allTags
        }
        return allTags.filter { $0.name.lowercased().contains(query) }
    }

    private var isExactMatchFound: Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allTags.contains { $0.name.lowercased() == query }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("关联标签", systemImage: "tag.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
            }

            if isEditable {
                editableTagContainer
            } else {
                readOnlyTagContainer
            }
        }
        // 新建标签弹窗
        .alert("新建标签", isPresented: $showingNewTagAlert) {
            TextField("标签名称", text: $newTagName)
            Button("取消", role: .cancel) {}
            Button("创建并关联") {
                createAndSelectTag(name: newTagName, colorHex: newTagColorHex)
            }
        }
    }

    // MARK: - 可编辑状态：标签药丸列表 + 多选下拉框触发器

    @ViewBuilder
    private var editableTagContainer: some View {
        HStack(alignment: .center, spacing: 8) {
            // 已选标签流展示 (可点击 x 移除)
            if selectedTagIds.isEmpty {
                Text("未选择标签")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(selectedTagIds, id: \.self) { tagId in
                            if let tag = allTags.first(where: { $0.id == tagId }) {
                                selectedTagPill(tag: tag)
                            }
                        }
                    }
                }
            }

            Spacer()

            // 搜索多选下拉弹窗触发按钮
            Button {
                searchText = ""
                showingTagPopover.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13))
                    Text("选择/搜索标签")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.accentColor.opacity(0.12))
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingTagPopover, arrowEdge: .bottom) {
                searchableTagPickerPopover
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - 已选标签小胶囊 (带移除小叉)

    @ViewBuilder
    private func selectedTagPill(tag: Tag) -> some View {
        let color = Color(hex: tag.colorHex) ?? .orange
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(tag.name)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(1)

            Button {
                toggleTag(tag.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(color.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 8)
        .padding(.trailing, 6)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(6)
    }

    // MARK: - 搜索与多选下拉浮窗 (Popover)

    @ViewBuilder
    private var searchableTagPickerPopover: some View {
        VStack(spacing: 0) {
            // 1. 搜索框
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("搜索标签名称...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.caption)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // 2. 标签多选勾选列表
            ScrollView {
                VStack(spacing: 2) {
                    if filteredTags.isEmpty && isExactMatchFound {
                        Text("无匹配标签")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(16)
                    } else {
                        ForEach(filteredTags) { tag in
                            let isSelected = selectedTagIds.contains(tag.id)
                            let color = Color(hex: tag.colorHex) ?? .orange

                            Button {
                                toggleTag(tag.id)
                            } label: {
                                HStack(spacing: 8) {
                                    // 复选框图标
                                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                        .foregroundColor(isSelected ? .accentColor : .secondary)
                                        .font(.system(size: 13))

                                    // 色彩标识
                                    Circle()
                                        .fill(color)
                                        .frame(width: 8, height: 8)

                                    // 标签名称
                                    Text(tag.name)
                                        .font(.caption)
                                        .foregroundColor(.primary)

                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
                            )
                        }
                    }

                    // 3. 快捷从搜索框创建新标签
                    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !query.isEmpty && !isExactMatchFound {
                        Divider()
                            .padding(.vertical, 4)

                        Button {
                            createAndSelectTag(name: query, colorHex: presetColors.randomElement() ?? "#FF9F0A")
                            searchText = ""
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)

                                Text("创建新标签「\(query)」")
                                    .font(.caption)
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
            }
            .frame(maxHeight: 180)

            Divider()

            // 4. 底部新建与完成栏
            HStack {
                Button {
                    newTagName = ""
                    newTagColorHex = presetColors.randomElement() ?? "#FF9F0A"
                    showingNewTagAlert = true
                } label: {
                    Label("新建标签", systemImage: "plus")
                        .font(.caption2)
                }
                .buttonStyle(.plain)

                Spacer()

                Button("完成") {
                    showingTagPopover = false
                }
                .font(.caption2.bold())
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        }
        .frame(width: 250)
    }

    // MARK: - 只读展示

    @ViewBuilder
    private var readOnlyTagContainer: some View {
        let assignedTags = allTags.filter { selectedTagIds.contains($0.id) }

        if assignedTags.isEmpty {
            Text("未添加标签")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            HStack(spacing: 6) {
                ForEach(assignedTags) { tag in
                    let tagColor = Color(hex: tag.colorHex) ?? .orange
                    HStack(spacing: 4) {
                        Circle()
                            .fill(tagColor)
                            .frame(width: 6, height: 6)
                        Text(tag.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tagColor.opacity(0.12))
                    .foregroundColor(tagColor)
                    .cornerRadius(6)
                }
            }
        }
    }

    private func toggleTag(_ tagId: UUID) {
        if let idx = selectedTagIds.firstIndex(of: tagId) {
            selectedTagIds.remove(at: idx)
        } else {
            selectedTagIds.append(tagId)
        }
    }

    private func createAndSelectTag(name: String, colorHex: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 如果已存在同名标签直接选中
        if let existing = allTags.first(where: { $0.name == trimmed }) {
            if !selectedTagIds.contains(existing.id) {
                selectedTagIds.append(existing.id)
            }
            return
        }

        // 调用回调并在当前草稿/条目中即时关联该真实新建的 Tag ID
        if let newTag = onAddTag?(trimmed, colorHex) {
            if !selectedTagIds.contains(newTag.id) {
                selectedTagIds.append(newTag.id)
            }
        }
    }
}
