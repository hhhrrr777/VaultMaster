import SwiftUI
import AppKit

/// 动态自定义字段编辑器组件 (支持 View / Edit 双模式)
public struct CustomFieldEditor: View {
    @Binding public var customFields: [CustomField]
    public var isEditable: Bool

    @State private var showingAddMenu: Bool = false

    public init(customFields: Binding<[CustomField]>, isEditable: Bool) {
        self._customFields = customFields
        self.isEditable = isEditable
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("自定义字段")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()

                if isEditable {
                    Menu {
                        ForEach(CustomFieldType.allCases) { type in
                            Button {
                                addField(type: type)
                            } label: {
                                Label(type.displayName, systemImage: type.iconName)
                            }
                        }
                    } label: {
                        Label("添加字段", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                    .menuStyle(.borderlessButton)
                }
            }

            if customFields.isEmpty {
                if !isEditable {
                    Text("暂无自定义字段")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach($customFields) { $field in
                        customFieldRow(field: $field)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - 字段行渲染

    @ViewBuilder
    private func customFieldRow(field: Binding<CustomField>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: field.wrappedValue.type.iconName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isEditable {
                    TextField("字段名称", text: field.name)
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Spacer()

                    Button {
                        removeField(id: field.wrappedValue.id)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red.opacity(0.8))
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .help("删除此字段")
                } else {
                    Text(field.wrappedValue.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            // 根据类型渲染具体输入或显示控件
            switch field.wrappedValue.type {
            case .text:
                if isEditable {
                    TextField("输入文本值", text: field.value)
                        .textFieldStyle(.roundedBorder)
                } else {
                    readOnlyTextRow(value: field.wrappedValue.value)
                }

            case .concealed:
                ConcealedSecureField(
                    title: "",
                    text: field.value,
                    placeholder: "输入敏感值",
                    isEditable: isEditable
                )

            case .multiline:
                if isEditable {
                    TextEditor(text: field.value)
                        .frame(minHeight: 60)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                        )
                } else {
                    Text(field.wrappedValue.value.isEmpty ? "（空）" : field.wrappedValue.value)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(6)
                }

            case .date:
                if isEditable {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: {
                                ISO8601DateFormatter().date(from: field.wrappedValue.value) ?? Date()
                            },
                            set: {
                                field.wrappedValue.value = ISO8601DateFormatter().string(from: $0)
                            }
                        ),
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                } else {
                    Text(formatDate(field.wrappedValue.value))
                        .font(.body)
                }

            case .boolean:
                Toggle(
                    field.wrappedValue.name.isEmpty ? "状态开关" : field.wrappedValue.name,
                    isOn: Binding(
                        get: { field.wrappedValue.value == "true" },
                        set: { field.wrappedValue.value = $0 ? "true" : "false" }
                    )
                )
                .disabled(!isEditable)
            }
        }
        .padding(.vertical, 4)
        Divider()
    }

    @ViewBuilder
    private func readOnlyTextRow(value: String) -> some View {
        HStack {
            Text(value.isEmpty ? "（空）" : value)
                .font(.body)
                .textSelection(.enabled)
            Spacer()

            if !value.isEmpty {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("复制内容")
            }
        }
    }

    private func addField(type: CustomFieldType) {
        let newField = CustomField(
            name: "新\(type.displayName)",
            type: type,
            value: type == .boolean ? "false" : ""
        )
        customFields.append(newField)
    }

    private func removeField(id: UUID) {
        customFields.removeAll(where: { $0.id == id })
    }

    private func formatDate(_ isoString: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: isoString) else {
            return isoString.isEmpty ? "未设置日期" : isoString
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
