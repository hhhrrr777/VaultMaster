import SwiftUI
import AppKit

/// 右侧资产详情与编辑/新建视图
public struct ItemDetailView: View {
    let itemId: UUID?
    @ObservedObject var vaultVM: VaultViewModel
    @ObservedObject var appState: AppState

    @State private var isEditingExisting: Bool = false
    @State private var draftItem: VaultItem?
    @State private var draftPayload: VaultItemPayload = VaultItemPayload()
    @State private var showingPasswordGenerator: Bool = false
    @State private var showingDeleteConfirm: Bool = false
    @FocusState private var isTitleFocused: Bool

    public init(itemId: UUID?, vaultVM: VaultViewModel, appState: AppState) {
        self.itemId = itemId
        self.vaultVM = vaultVM
        self.appState = appState
    }

    private var currentItem: VaultItem? {
        guard let id = itemId else { return nil }
        return vaultVM.items.first(where: { $0.id == id })
    }

    private var isEditing: Bool {
        appState.isCreatingNewItem || isEditingExisting
    }

    public var body: some View {
        Group {
            if appState.isCreatingNewItem {
                // 新建录入表单模式
                newItemCreationForm
            } else if let item = currentItem {
                // 已有项目浏览 / 编辑模式
                existingItemContent(for: item)
            } else {
                // 无选中项目空状态
                noSelectionView
            }
        }
        .frame(minWidth: 400, idealWidth: 500)
        .onChange(of: itemId) { _, newId in
            isEditingExisting = false
            if newId != nil {
                appState.isCreatingNewItem = false
            }
            loadDraft(for: newId)
        }
        .onChange(of: appState.isCreatingNewItem) { _, isCreating in
            if isCreating {
                prepareNewItemDraft(category: appState.creatingCategory)
            }
        }
        .onAppear {
            if appState.isCreatingNewItem {
                prepareNewItemDraft(category: appState.creatingCategory)
            } else {
                loadDraft(for: itemId)
            }
        }
        .sheet(isPresented: $showingPasswordGenerator) {
            PasswordGeneratorSheet { newPassword in
                let currentCategory = appState.isCreatingNewItem ? appState.creatingCategory : (currentItem?.category ?? .login)
                if currentCategory == .devCredential {
                    draftPayload.privateKeyOrToken = newPassword
                } else {
                    draftPayload.password = newPassword
                }
            }
        }
    }

    // MARK: - 1. 新建资产录入表单视图 (未点保存前不入库)

    @ViewBuilder
    private var newItemCreationForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 顶部新建类型、标题、文件夹与标签选择
                creationHeaderSection

                Divider()

                // 表单专属字段
                categorySpecificFields(category: appState.creatingCategory)

                Divider()

                // 动态自定义字段
                CustomFieldEditor(
                    customFields: $draftPayload.customFields,
                    isEditable: true
                )
            }
            .padding(24)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("取消") {
                    appState.cancelCreatingItem()
                }
                .keyboardShortcut(.cancelAction)

                Button("保存") {
                    saveNewItem()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    @ViewBuilder
    private var creationHeaderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(appState.creatingCategory.themeColor.opacity(0.18))
                        .frame(width: 52, height: 52)

                    Image(systemName: appState.creatingCategory.iconName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(appState.creatingCategory.themeColor)
                }

                VStack(alignment: .leading, spacing: 8) {
                    TextField(appState.creatingCategory == .login ? "输入网站或应用名称 (如: GitHub / Google / ChatGPT)" : "输入资产标题 (如: 个人邮箱 / 公司服务器 / 招行信用卡)", text: Binding(
                        get: { draftItem?.title ?? "" },
                        set: { draftItem?.title = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.title3.bold())
                    .focused($isTitleFocused)

                    HStack(spacing: 12) {
                        // 分类选择
                        Picker("资产分类", selection: $appState.creatingCategory) {
                            ForEach(ItemCategory.allCases) { cat in
                                Label(cat.displayName, systemImage: cat.iconName).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: appState.creatingCategory) { _, newCat in
                            draftItem?.category = newCat
                        }

                        // 文件夹归类
                        Picker("文件夹", selection: Binding(
                            get: { draftItem?.folderId },
                            set: { draftItem?.folderId = $0 }
                        )) {
                            Text("无文件夹").tag(nil as UUID?)
                            ForEach(vaultVM.folders) { folder in
                                Text(folder.name).tag(folder.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }

            // 标签选择器
            TagSelectorView(
                selectedTagIds: Binding(
                    get: { draftItem?.tagIds ?? [] },
                    set: { draftItem?.tagIds = $0 }
                ),
                allTags: vaultVM.tags,
                isEditable: true,
                onAddTag: { name, colorHex in
                    vaultVM.addTag(name: name, colorHex: colorHex)
                }
            )
            .padding(.top, 4)
        }
        .onAppear {
            isTitleFocused = true
        }
    }

    // MARK: - 2. 已有资产详情 / 编辑视图

    @ViewBuilder
    private func existingItemContent(for item: VaultItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 顶部标题、文件夹与标签信息
                existingHeaderSection(item: item)

                Divider()

                // 根据不同类型展示专属字段
                categorySpecificFields(category: item.category)

                Divider()

                // 动态自定义字段
                CustomFieldEditor(
                    customFields: $draftPayload.customFields,
                    isEditable: isEditingExisting
                )

                // 底部修改时间与安全信息
                footerSection(item: item)
            }
            .padding(24)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if isEditingExisting {
                    Button("取消") {
                        cancelEditingExisting()
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("完成") {
                        saveExistingChanges()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                } else {
                    Button {
                        vaultVM.toggleFavorite(item)
                    } label: {
                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                            .foregroundColor(item.isFavorite ? .yellow : .secondary)
                    }
                    .help(item.isFavorite ? "取消收藏" : "标为收藏")

                    Button("编辑") {
                        isEditingExisting = true
                    }
                    .buttonStyle(.bordered)
                    .help("编辑资产")

                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .help(item.isTrash ? "永久删除此项目" : "移至废纸篓")
                }
            }
        }
        // 删除确认弹窗
        .alert(item.isTrash ? "确定要永久删除此项目吗？" : "确定要将此项目移至废纸篓吗？", isPresented: $showingDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button(item.isTrash ? "永久删除" : "移至废纸篓", role: .destructive) {
                vaultVM.deleteItem(item)
                appState.selectedItemId = nil
            }
        } message: {
            if item.isTrash {
                Text("此操作将永久抹除「\(item.title)」的密文数据，不可恢复。")
            } else {
                Text("项目「\(item.title)」将被移至废纸篓，您可以随时在废纸篓中还原或彻底清空。")
            }
        }
    }

    @ViewBuilder
    private func existingHeaderSection(item: VaultItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(item.category.themeColor.opacity(0.18))
                        .frame(width: 52, height: 52)

                    Image(systemName: item.category.iconName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(item.category.themeColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    if isEditingExisting {
                        TextField("资产标题", text: Binding(
                            get: { draftItem?.title ?? item.title },
                            set: { draftItem?.title = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.title2.bold())
                    } else {
                        Text(item.title)
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                    }

                    HStack(spacing: 10) {
                        Text(item.category.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(item.category.themeColor.opacity(0.15))
                            .foregroundColor(item.category.themeColor)
                            .cornerRadius(6)

                        if isEditingExisting {
                            Picker("文件夹", selection: Binding(
                                get: { draftItem?.folderId },
                                set: { draftItem?.folderId = $0 }
                            )) {
                                Text("无文件夹").tag(nil as UUID?)
                                ForEach(vaultVM.folders) { folder in
                                    Text(folder.name).tag(folder.id as UUID?)
                                }
                            }
                            .pickerStyle(.menu)
                        } else if let folder = vaultVM.folders.first(where: { $0.id == item.folderId }) {
                            Label(folder.name, systemImage: folder.icon)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }

            // 标签选择与展示
            TagSelectorView(
                selectedTagIds: Binding(
                    get: { isEditingExisting ? (draftItem?.tagIds ?? []) : item.tagIds },
                    set: { newTagIds in
                        if isEditingExisting {
                            draftItem?.tagIds = newTagIds
                        }
                    }
                ),
                allTags: vaultVM.tags,
                isEditable: isEditingExisting,
                onAddTag: { name, colorHex in
                    vaultVM.addTag(name: name, colorHex: colorHex)
                }
            )
        }
    }

    // MARK: - 3. 空状态提示

    @ViewBuilder
    private var noSelectionView: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.square.stack")
                .font(.system(size: 46))
                .foregroundColor(.secondary.opacity(0.35))
            Text("未选择资产项目")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("从中间列表中选择一个项目以查看详情，或点击下方按钮新建资产。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                appState.startCreatingItem(category: .login)
            } label: {
                Label("新建资产项目", systemImage: "plus.circle.fill")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 4. 各分类专属字段

    @ViewBuilder
    private func categorySpecificFields(category: ItemCategory) -> some View {
        switch category {
        case .login:
            loginFieldsView
        case .apiKey:
            apiKeyFieldsView
        case .devCredential:
            devCredentialFieldsView
        case .paymentCard:
            paymentCardFieldsView
        case .identity:
            identityFieldsView
        case .secureNote:
            secureNoteFieldsView
        }
    }

    // 1. 网站与应用专属字段 (Apple 原生毛玻璃卡片风格)
    @ViewBuilder
    private var loginFieldsView: some View {
        VStack(spacing: 16) {
            LoginCredentialsCardView(
                username: $draftPayload.username,
                email: $draftPayload.email,
                password: $draftPayload.password,
                isEditing: isEditing,
                onOpenGenerator: {
                    showingPasswordGenerator = true
                }
            )

            WebAddressCardView(
                urlString: $draftPayload.url,
                isEditing: isEditing
            )

            TOTPCardView(
                totpSecret: $draftPayload.totpSecret,
                isEditing: isEditing
            )

            SecureNotesCardView(
                notes: $draftPayload.notes,
                isEditing: isEditing
            )
        }
    }

    // 2. API Key 专属字段 (直接输入，不包含密码自动生成器)
    @ViewBuilder
    private var apiKeyFieldsView: some View {
        VStack(spacing: 14) {
            fieldRow(title: "Key ID / Client ID", value: $draftPayload.keyId, placeholder: "ak_live_xxxxxxxx")
            fieldRow(title: "Secret / API Key", value: $draftPayload.apiKeySecret, placeholder: "sk_live_xxxxxxxx")
            fieldRow(title: "Endpoint API 接口地址", value: $draftPayload.endpoint, placeholder: "https://api.openai.com/v1", isUrl: true)
            fieldRow(title: "自定义 Header / 配置", value: $draftPayload.customHeaders, placeholder: "Bearer Token...")
            notesFieldView
        }
    }

    // 3. 开发凭据专属字段 (SSH / 数据库 / 云服务 / Access Token)
    @ViewBuilder
    private var devCredentialFieldsView: some View {
        VStack(spacing: 14) {
            fieldRow(title: "凭据类型 / 协议", value: $draftPayload.credentialType, placeholder: "SSH / MySQL / PostgreSQL / Redis / AWS / GitHub Token")
            HStack(spacing: 14) {
                fieldRow(title: "服务器主机 / IP 地址", value: $draftPayload.host, placeholder: "192.168.1.100 或 db.example.com")
                fieldRow(title: "端口号", value: $draftPayload.port, placeholder: "22 / 3306 / 6379")
            }
            fieldRow(title: "用户名 / 账户", value: $draftPayload.username, placeholder: "root / ubuntu / admin")
            ConcealedSecureField(
                title: "密码 / 私钥 / Access Token",
                text: $draftPayload.privateKeyOrToken,
                placeholder: "请输入或粘贴敏感凭据内容",
                isEditable: isEditing,
                onGeneratePassword: {
                    showingPasswordGenerator = true
                }
            )
            notesFieldView
        }
    }

    // 4. 银行卡专属字段
    @ViewBuilder
    private var paymentCardFieldsView: some View {
        VStack(spacing: 14) {
            fieldRow(title: "持卡人姓名", value: $draftPayload.cardholderName, placeholder: "ZHANG SAN")
            fieldRow(title: "银行卡号", value: $draftPayload.cardNumber, placeholder: "6222 0000 0000 0000")
            HStack(spacing: 14) {
                fieldRow(title: "卡片类型", value: $draftPayload.cardType, placeholder: "Visa / Mastercard / 银联")
                fieldRow(title: "发卡银行", value: $draftPayload.bankName, placeholder: "招商银行 / 建设银行")
            }
            HStack(spacing: 14) {
                fieldRow(title: "有效期 (MM/YY)", value: $draftPayload.expiryDate, placeholder: "12/28")
                ConcealedSecureField(title: "CVV / 安全码", text: $draftPayload.cvv, placeholder: "888", isEditable: isEditing)
                ConcealedSecureField(title: "取款 PIN 码", text: $draftPayload.pin, placeholder: "6 位密码", isEditable: isEditing)
            }
            notesFieldView
        }
    }

    // 5. 身份信息专属字段
    @ViewBuilder
    private var identityFieldsView: some View {
        VStack(spacing: 14) {
            fieldRow(title: "姓名", value: $draftPayload.fullName, placeholder: "张三")
            fieldRow(title: "证件类型", value: $draftPayload.documentType, placeholder: "身份证 / 护照 / 驾照")
            fieldRow(title: "证件号码", value: $draftPayload.idNumber, placeholder: "110101199003072345")
            HStack(spacing: 14) {
                fieldRow(title: "颁发日期", value: $draftPayload.issueDate, placeholder: "2020-01-01")
                fieldRow(title: "过期日期", value: $draftPayload.expirationDate, placeholder: "2030-01-01")
            }
            fieldRow(title: "签发机关", value: $draftPayload.issuingAuthority, placeholder: "北京市公安局")
            notesFieldView
        }
    }

    // 6. 安全便签专属字段
    @ViewBuilder
    private var secureNoteFieldsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("加密便签内容")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if isEditing {
                TextEditor(text: $draftPayload.notes)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 180)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                            )
                    )
            } else {
                Text(draftPayload.notes.isEmpty ? "（暂无便签内容）" : draftPayload.notes)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(draftPayload.notes.isEmpty ? .secondary : .primary)
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    )
            }
        }
    }

    // 备注通用字段
    @ViewBuilder
    private var notesFieldView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("备注信息")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if isEditing {
                TextEditor(text: $draftPayload.notes)
                    .frame(minHeight: 70)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    )
            } else {
                if !draftPayload.notes.isEmpty {
                    Text(draftPayload.notes)
                        .font(.subheadline)
                        .textSelection(.enabled)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                        .cornerRadius(6)
                }
            }
        }
    }

    // 通用字段行
    @ViewBuilder
    private func fieldRow(title: String, value: Binding<String>, placeholder: String, isUrl: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                if isEditing {
                    TextField(placeholder, text: value)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(value.wrappedValue.isEmpty ? "（未填写）" : value.wrappedValue)
                        .font(.body)
                        .foregroundColor(value.wrappedValue.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                    
                    Spacer()

                    if isUrl && !value.wrappedValue.isEmpty, let url = URL(string: value.wrappedValue) {
                        Button {
                            NSWorkspace.shared.open(url)
                        } label: {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("在浏览器中打开")
                    }

                    if !value.wrappedValue.isEmpty {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(value.wrappedValue, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("复制内容")
                    }
                }
            }
        }
    }

    // 底部信息
    @ViewBuilder
    private func footerSection(item: VaultItem) -> some View {
        HStack {
            Text("最后更新: \(formatDate(item.updatedAt))")
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text("安全级别: AES-256-GCM 密文落盘")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.top, 10)
    }

    // MARK: - 5. 业务草稿与保存逻辑

    /// 准备新建草稿
    private func prepareNewItemDraft(category: ItemCategory) {
        var folderId: UUID? = nil
        var initialTagIds: [UUID] = []

        if case .folder(let fId) = appState.selectedFilter {
            folderId = fId
        } else if case .tag(let tId) = appState.selectedFilter {
            initialTagIds.append(tId)
        }

        draftItem = VaultItem(
            title: "",
            category: category,
            folderId: folderId,
            tagIds: initialTagIds
        )
        draftPayload = VaultItemPayload()
    }

    /// 执行新建保存
    private func saveNewItem() {
        guard var item = draftItem else { return }
        if item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            item.title = "新建\(item.category.shortName)"
        }
        vaultVM.saveItem(item: &item, payload: draftPayload)
        appState.isCreatingNewItem = false
        appState.selectedItemId = item.id
    }

    /// 加载已有条目草稿
    private func loadDraft(for id: UUID?) {
        guard let id = id, let item = vaultVM.items.first(where: { $0.id == id }) else {
            draftItem = nil
            draftPayload = VaultItemPayload()
            return
        }
        draftItem = item
        draftPayload = vaultVM.getPayload(for: item)
    }

    /// 保存已有条目修改
    private func saveExistingChanges() {
        guard var item = draftItem ?? currentItem else { return }
        vaultVM.saveItem(item: &item, payload: draftPayload)
        isEditingExisting = false
    }

    /// 取消已有条目修改
    private func cancelEditingExisting() {
        loadDraft(for: itemId)
        isEditingExisting = false
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
