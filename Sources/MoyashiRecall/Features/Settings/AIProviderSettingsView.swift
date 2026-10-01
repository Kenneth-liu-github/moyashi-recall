import SwiftUI

public struct AIProviderSettingsView: View {
    @EnvironmentObject private var language: LanguageStore

    // Editor draft
    @State private var profileName = ""
    @State private var provider: AIProviderKind = .openAI
    @State private var modelID = ""
    @State private var apiKeyDraft = ""

    // Profile state
    @State private var savedProfiles: [AIConfigurationProfile] = []
    @State private var activeProfileID: UUID?
    @State private var selectedProfileID: UUID?

    // UI state
    @State private var hasStoredCredential = false
    @State private var editorMode: AIConfigurationEditorMode?
    @State private var originalEditingProvider: AIProviderKind?
    @State private var statusMessage: String?
    @State private var isTestingConnection = false
    @State private var showDeleteConfirmation = false
    @State private var showSaveConfirmation = false
    @State private var connectionStatus:
        AIConnectionStatus = .untested

    private let configurationStore = AIConfigurationStore()
    private let profileStore = AIConfigurationProfileStore()
    private let credentialStore = KeychainCredentialStore()

    public init() {}

    private var selectedProfileForDeletion:
        AIConfigurationProfile? {
        guard let selectedProfileID else {
            return nil
        }

        return savedProfiles.first {
            $0.id == selectedProfileID
        }
    }

    private var activeProfile: AIConfigurationProfile? {
        guard let activeProfileID else {
            return nil
        }

        return savedProfiles.first {
            $0.id == activeProfileID
        }
    }

    private var providerBinding: Binding<AIProviderKind> {
        Binding(
            get: {
                provider
            },
            set: { newProvider in
                guard provider != newProvider else {
                    return
                }

                provider = newProvider
                modelID = defaultModelID(
                    for: newProvider
                )
                apiKeyDraft = ""
            }
        )
    }

    public var body: some View {
        Form {
            currentConfigurationSection

            if isEditingActiveProfile {
                editorSection
            }

            connectionSection

            savedProfilesSection

            if isEditingSavedProfile
                || isCreatingProfile {
                editorSection
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle(
            language.text(
                "AI 设置",
                "AI設定"
            )
        )
        .alert(
            language.text(
                "确定修改？",
                "変更を確定しますか？"
            ),
            isPresented:
                $showSaveConfirmation
        ) {
            Button(
                language.text(
                    "取消",
                    "キャンセル"
                ),
                role: .cancel
            ) {}

            Button(
                language.text(
                    "确定修改",
                    "変更を確定"
                )
            ) {
                saveEditor()
            }
        } message: {
            Text(
                modificationConfirmationMessage
            )
        }

        .alert(
            language.text(
                "确定删除？",
                "削除しますか？"
            ),
            isPresented:
                $showDeleteConfirmation,
            presenting:
                selectedProfileForDeletion
        ) { profile in
            Button(
                language.text(
                    "取消",
                    "キャンセル"
                ),
                role: .cancel
            ) {}

            Button(
                language.text(
                    "删除",
                    "削除"
                ),
                role: .destructive
            ) {
                deleteSelectedProfile()
            }
        } message: { profile in
            if profile.id == activeProfileID {
                Text(
                    language.text(
                        "将删除配置「\(profile.name)」及其独立 API Key。该配置当前正在使用；删除后不会自动切换到其他配置。已生成的知识点、卡片和复习记录不会被删除。",
                        "設定「\(profile.name)」とその専用API Keyを削除します。この設定は現在使用中です。削除後、他の設定には自動で切り替わりません。既存の知識・カード・復習履歴は削除されません。"
                    )
                )
            } else {
                Text(
                    language.text(
                        "将删除配置「\(profile.name)」及其独立 API Key。当前正在使用的配置不会改变；已生成的知识点、卡片和复习记录不会被删除。",
                        "設定「\(profile.name)」とその専用API Keyを削除します。現在使用中の設定は変更されません。既存の知識・カード・復習履歴は削除されません。"
                    )
                )
            }
        }

        .onAppear {
            loadConfiguration()
        }
    }

    // MARK: - Current configuration

    private var currentConfigurationSection: some View {
        Section {
            if let profile = activeProfile {
                LabeledContent {
                    HStack(spacing: 8) {
                        Text(profile.name)
                            .foregroundStyle(
                                AppTheme.accent
                            )

                        Text(
                            language.text(
                                "当前",
                                "現在"
                            )
                        )
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(
                            .horizontal,
                            8
                        )
                        .padding(
                            .vertical,
                            3
                        )
                        .background(
                            AppTheme.accent,
                            in: Capsule()
                        )
                    }
                } label: {
                    Text(
                        language.text(
                            "配置名称",
                            "設定名"
                        )
                    )
                }

                LabeledContent(
                    "Provider",
                    value:
                        profile
                            .provider
                            .displayName
                )

                LabeledContent(
                    language.text(
                        "模型 ID",
                        "モデルID"
                    ),
                    value:
                        profile.modelID
                )

                LabeledContent {
                    Text(
                        profileHasCredential(
                            profile
                        )
                        ? "••••••••••••"
                        : "none"
                    )
                    .foregroundStyle(
                        profileHasCredential(
                            profile
                        )
                        ? AppTheme.accent
                        : AppTheme.muted
                    )
                } label: {
                    Text("API Key")
                }

                Button {
                    beginEditCurrentProfile()
                } label: {
                    Label(
                        language.text(
                            "编辑当前配置",
                            "現在の設定を編集"
                        ),
                        systemImage: "pencil"
                    )
                }
                .disabled(
                    editorMode != nil
                )

            } else {
                ContentUnavailableView(
                    language.text(
                        "尚未加载 AI 配置",
                        "AI設定が読み込まれていません"
                    ),
                    systemImage:
                        "cpu"
                )
            }
        } header: {
            Text(
                language.text(
                    "当前配置",
                    "現在の設定"
                )
            )
        } footer: {
            Text(
                language.text(
                    "当前正在使用的 AI 配置。在这里编辑并保存后，修改将立即生效。",
                    "現在使用中のAI設定です。ここで編集して保存すると、変更はすぐに反映されます。"
                )
            )
        }
    }

    // MARK: - Credential display

    private var credentialSection: some View {
        Section {
            LabeledContent {
                Text(
                    hasStoredCredential
                        ? "••••••••••••••••"
                        : language.text(
                            "未配置",
                            "未設定"
                        )
                )
                .foregroundStyle(
                    hasStoredCredential
                        ? AppTheme.accent
                        : AppTheme.muted
                )
            } label: {
                Text("API Key")
            }
        } header: {
            Text(
                language.text(
                    "安全凭证",
                    "安全な認証情報"
                )
            )
        } footer: {
            Text(
                language.text(
                    "API Key 仅保存在 Apple Keychain，不写入 UserDefaults、学习数据库或 GitHub。",
                    "API KeyはApple Keychainのみに保存され、UserDefaults、学習データベース、GitHubには保存されません。"
                )
            )
        }
    }

    // MARK: - Connection + edit

    private var connectionSection: some View {
        Section {
            Button {
                Task {
                    await testConnection()
                }
            } label: {
                HStack {
                    if isTestingConnection {
                        ProgressView()
                    }

                    Text(
                        language.text(
                            "测试 AI 连接",
                            "AI接続をテスト"
                        )
                    )
                }
            }
            .disabled(
                isTestingConnection
                || activeProfile == nil
                || !hasStoredCredential
            )

            HStack {
                Text(
                    language.text(
                        "测试状态",
                        "テスト状態"
                    )
                )

                Spacer()

                Circle()
                    .fill(
                        connectionStatusColor
                    )
                    .frame(
                        width: 10,
                        height: 10
                    )

                Text(connectionStatusText)
                    .foregroundStyle(
                        connectionStatusColor
                    )
            }

            Button {
                beginEditCurrentProfile()
            } label: {
                Label(
                    language.text(
                        "编辑当前 AI 配置",
                        "現在のAI設定を編集"
                    ),
                    systemImage: "pencil"
                )
            }
            .disabled(
                activeProfile == nil
                || editorMode != nil
            )
        } footer: {
            Text(
                language.text(
                    "测试连接使用当前已加载并保存的 AI 配置，不使用尚未保存的编辑内容。",
                    "接続テストは現在読み込まれ保存済みのAI設定を使用し、未保存の編集内容は使用しません。"
                )
            )
        }
    }

    // MARK: - Editor

    private var editorSection: some View {
        Section {
            HStack(spacing: 10) {
                Label(
                    editorContextTitle,
                    systemImage:
                        editorContextIcon
                )
                .fontWeight(.semibold)

                Spacer()

                Text(editorContextTag)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        editorContextTagColor
                    )
                    .padding(
                        .horizontal,
                        8
                    )
                    .padding(
                        .vertical,
                        3
                    )
                    .background(
                        editorContextTagBackground,
                        in: Capsule()
                    )
            }

            Text(editorContextMessage)
                .font(.caption)
                .foregroundStyle(
                    AppTheme.muted
                )

            TextField(
                language.text(
                    "配置名称",
                    "設定名"
                ),
                text: $profileName
            )

            Picker(
                "Provider",
                selection: providerBinding
            ) {
                ForEach(
                    AIProviderKind.allCases
                ) { item in
                    Text(item.displayName)
                        .tag(item)
                }
            }

            switch provider {
            case .deepSeek:
                Picker(
                    language.text(
                        "模型 ID",
                        "モデルID"
                    ),
                    selection: $modelID
                ) {
                    Text("deepseek-flash")
                        .tag("deepseek-flash")

                    Text("deepseek-v4-pro")
                        .tag("deepseek-v4-pro")
                }

            case .kimi:
                Picker(
                    language.text(
                        "模型 ID",
                        "モデルID"
                    ),
                    selection: $modelID
                ) {
                    Text("kimi-k2.6")
                        .tag("kimi-k2.6")

                    Text("kimi-k2.7-code")
                        .tag("kimi-k2.7-code")
                }

            case .openAI,
                 .anthropic:
                TextField(
                    language.text(
                        "模型 ID",
                        "モデルID"
                    ),
                    text: $modelID
                )
            }

            SecureField(
                editorMode == .creating
                    ? language.text(
                        "API Key（可选）",
                        "API Key（任意）"
                    )
                    : language.text(
                        "新的 API Key（留空则保持不变）",
                        "新しいAPI Key（空欄なら変更なし）"
                    ),
                text: $apiKeyDraft
            )

            if editorMode?
                .isEditingExistingProfile
                == true {
                LabeledContent {
                    Text(
                        hasStoredCredential
                            ? "••••••••••••"
                            : "none"
                    )
                        .foregroundStyle(
                            AppTheme.accent
                        )
                } label: {
                    Text(
                        language.text(
                            "当前 API Key",
                            "現在のAPI Key"
                        )
                    )
                }
            }

            HStack(spacing: 12) {
                Button {
                    cancelEditing()
                } label: {
                    Text(
                        language.text(
                            "取消",
                            "キャンセル"
                        )
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(.bordered)

                Button {
                    requestSaveEditor()
                } label: {
                    Text(
                        language.text(
                            "保存",
                            "保存"
                        )
                    )
                    .fontWeight(.semibold)
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
            }
        } header: {
            Text(
                editorMode == .creating
                    ? language.text(
                        "新建 AI 配置",
                        "新しいAI設定"
                    )
                    : language.text(
                        "编辑当前 AI 配置",
                        "現在のAI設定を編集"
                    )
            )
        } footer: {
            Text(
                editorMode == .creating
                    ? language.text(
                        "新建配置必须填写 API Key。保存后不会自动切换当前配置，请在下方配置列表中加载。",
                        "新規設定ではAPI Keyが必要です。保存しても自動では切り替わりません。下の設定一覧から読み込んでください。"
                    )
                    : language.text(
                        "编辑当前配置时，API Key 留空表示继续使用现有 Key。只有点击“保存”才会写入修改。",
                        "現在の設定を編集する場合、API Keyを空欄にすると既存Keyを保持します。「保存」を押した場合のみ変更が書き込まれます。"
                    )
            )
        }
    }

    // MARK: - Saved profiles

    private var savedProfilesSection: some View {
        Section {
            // ------------------------------------------------
            // List actions
            // ------------------------------------------------
            HStack(spacing: 24) {
                Button {
                    beginNewProfile()
                } label: {
                    Label(
                        language.text(
                            "新建",
                            "新規"
                        ),
                        systemImage:
                            "plus.circle"
                    )
                }
                .disabled(
                    editorMode != nil
                )

                Button {
                    editSelectedProfile()
                } label: {
                    Label(
                        language.text(
                            "编辑",
                            "編集"
                        ),
                        systemImage:
                            "pencil"
                    )
                }
                .disabled(
                    editorMode != nil
                    || selectedProfileID == nil
                    || selectedProfileID
                        == activeProfileID
                )

                Button(
                    role: .destructive
                ) {
                    showDeleteConfirmation =
                        true
                } label: {
                    Label(
                        language.text(
                            "删除",
                            "削除"
                        ),
                        systemImage:
                            "trash"
                    )
                }
                .disabled(
                    editorMode != nil
                    || selectedProfileID == nil
                )

                Spacer()
            }
            .buttonStyle(.borderless)

            // ------------------------------------------------
            // Saved profiles
            // ------------------------------------------------
            ForEach(
                savedProfiles
            ) { profile in
                Button {
                    selectedProfileID =
                        profile.id
                } label: {
                    HStack(
                        alignment: .center,
                        spacing: 12
                    ) {
                        VStack(
                            alignment: .leading,
                            spacing: 5
                        ) {
                            HStack(spacing: 8) {
                                Text(profile.name)
                                    .fontWeight(
                                        .semibold
                                    )

                                Text(
                                    profile.id
                                        == activeProfileID
                                    ? language.text(
                                        "当前",
                                        "現在"
                                    )
                                    : language.text(
                                        "列表",
                                        "一覧"
                                    )
                                )
                                .font(.caption2)
                                .fontWeight(
                                    .semibold
                                )
                                .foregroundStyle(
                                    profile.id
                                        == activeProfileID
                                    ? Color.white
                                    : AppTheme.muted
                                )
                                .padding(
                                    .horizontal,
                                    7
                                )
                                .padding(
                                    .vertical,
                                    2
                                )
                                .background {
                                    if profile.id
                                        == activeProfileID {
                                        Capsule()
                                            .fill(
                                                AppTheme
                                                    .accent
                                            )
                                    } else {
                                        Capsule()
                                            .fill(
                                                Color
                                                    .secondary
                                                    .opacity(
                                                        0.12
                                                    )
                                            )
                                    }
                                }
                            }

                            Text(
                                "\(profile.provider.displayName) · \(profile.modelID)"
                            )
                            .font(.subheadline)

                            Text(
                                "API Key · "
                                + profileCredentialDisplay(
                                    profile
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(
                                AppTheme.muted
                            )
                        }

                        Spacer()

                        Image(
                            systemName:
                                selectedProfileID
                                    == profile.id
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .foregroundStyle(
                            selectedProfileID
                                == profile.id
                            ? AppTheme.accent
                            : AppTheme.muted
                        )
                    }
                    .contentShape(
                        Rectangle()
                    )
                }
                .buttonStyle(.plain)
            }

            // ------------------------------------------------
            // Load selected saved profile
            // ------------------------------------------------
            if let selectedProfileID,
               selectedProfileID
                    != activeProfileID,
               savedProfiles.contains(
                    where: {
                        $0.id
                            == selectedProfileID
                    }
               ) {
                Button {
                    activateSelectedProfile()
                } label: {
                    Label(
                        language.text(
                            "加载此配置",
                            "この設定を読み込む"
                        ),
                        systemImage:
                            "play.circle.fill"
                    )
                    .fontWeight(
                        .semibold
                    )
                }
                .disabled(
                    editorMode != nil
                )
            }
        } header: {
            Text(
                language.text(
                    "配置列表",
                    "設定一覧"
                )
            )
        } footer: {
            Text(
                language.text(
                    "管理已保存的 AI 配置。编辑列表配置只会更新保存内容，不会立即生效；只有点击“加载此配置”后，才会成为当前配置。",
                    "保存済みAI設定を管理します。一覧の設定を編集してもすぐには反映されません。「この設定を読み込む」を押した後に現在の設定になります。"
                )
            )
        }
    }

    private var isEditingActiveProfile: Bool {
        if case .editingActive = editorMode {
            return true
        }

        return false
    }

    private var isEditingSavedProfile: Bool {
        if case .editingSaved = editorMode {
            return true
        }

        return false
    }

    private var isCreatingProfile: Bool {
        editorMode == .creating
    }

    private var editorContextTitle: String {
        switch editorMode {
        case .editingActive:
            return language.text(
                "编辑当前配置",
                "現在の設定を編集"
            )

        case .editingSaved:
            return language.text(
                "编辑列表配置",
                "一覧設定を編集"
            )

        case .creating:
            return language.text(
                "新建 AI 配置",
                "新しいAI設定"
            )

        case nil:
            return ""
        }
    }

    private var editorContextTag: String {
        switch editorMode {
        case .editingActive:
            return language.text(
                "当前",
                "現在"
            )

        case .editingSaved,
             .creating:
            return language.text(
                "列表",
                "一覧"
            )

        case nil:
            return ""
        }
    }

    private var editorContextIcon: String {
        switch editorMode {
        case .editingActive:
            return "bolt.fill"

        case .editingSaved:
            return "pencil"

        case .creating:
            return "plus.circle"

        case nil:
            return "circle"
        }
    }

    private var editorContextMessage: String {
        switch editorMode {
        case .editingActive:
            return language.text(
                "此处修改的是当前正在使用的 AI 配置。点击“保存”后立即生效。",
                "現在使用中のAI設定を編集しています。「保存」するとすぐに反映されます。"
            )

        case .editingSaved:
            return language.text(
                "此处只修改配置列表中的保存内容。点击“保存”不会切换当前 AI；需要另外点击“加载此配置”才会生效。",
                "一覧に保存された設定のみを編集します。「保存」しても現在のAIは切り替わりません。「この設定を読み込む」で有効になります。"
            )

        case .creating:
            return language.text(
                "新配置保存后会加入配置列表，但不会自动成为当前配置。",
                "新しい設定は一覧に保存されますが、自動では現在の設定になりません。"
            )

        case nil:
            return ""
        }
    }

    private var editorContextTagColor: Color {
        switch editorMode {
        case .editingActive:
            return .white

        case .editingSaved,
             .creating,
             nil:
            return AppTheme.muted
        }
    }

    private var editorContextTagBackground: Color {
        switch editorMode {
        case .editingActive:
            return AppTheme.accent

        case .editingSaved,
             .creating,
             nil:
            return Color.secondary
                .opacity(0.12)
        }
    }

    private func profileCredentialDisplay(
        _ profile: AIConfigurationProfile
    ) -> String {
        profileHasCredential(profile)
            ? "••••••••••••"
            : "none"
    }

    private func profileHasCredential(
        _ profile: AIConfigurationProfile
    ) -> Bool {
        do {
            guard let secret =
                try credentialStore.read(
                    account:
                        profile
                            .credentialAccount
                )
            else {
                return false
            }

            return !secret
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Load

    private func loadConfiguration() {
        savedProfiles =
            profileStore.profiles()

        activeProfileID =
            profileStore.activeProfileID()

        selectedProfileID =
            activeProfileID

        editorMode = nil
        apiKeyDraft = ""
        statusMessage = nil
        connectionStatus = .untested

        refreshCredentialState()
    }

    // MARK: - Edit current

    private func beginEditCurrentProfile() {
        guard let profile = activeProfile else {
            return
        }

        editorMode = .editingActive(
            profile.id
        )
        originalEditingProvider =
            profile.provider

        profileName = profile.name
        provider = profile.provider

        let storedModel =
            profile.modelID
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        modelID =
            storedModel.isEmpty
            ? defaultModelID(
                for: profile.provider
            )
            : storedModel

        apiKeyDraft = ""

        statusMessage = nil
    }

    // MARK: - Create

    private func beginNewProfile() {
        editorMode = .creating
        originalEditingProvider = nil

        profileName = ""
        provider =
            activeProfile?.provider
            ?? .openAI

        modelID =
            defaultModelID(
                for: provider
            )

        apiKeyDraft = ""
        statusMessage = nil
    }

    private func closeEditor() {
        withAnimation(.easeInOut(duration: 0.2)) {
            editorMode = nil
        }

        originalEditingProvider = nil
        apiKeyDraft = ""

        // Draft values are no longer needed once editor closes.
        profileName = ""
        modelID = ""

        refreshCredentialState()
    }

    // MARK: - Cancel

    private func cancelEditing() {
        closeEditor()

        connectionStatus = .untested

        statusMessage = language.text(
            "已取消修改。",
            "変更をキャンセルしました。"
        )
    }

    private var profileBeingEdited:
        AIConfigurationProfile? {

        let targetID: UUID?

        switch editorMode {
        case .editingActive(let id):
            targetID = id

        case .editingSaved(let id):
            targetID = id

        case .creating,
             nil:
            targetID = nil
        }

        guard let targetID else {
            return nil
        }

        return savedProfiles.first {
            $0.id == targetID
        }
    }

    private var hasEditedConfigurationChanges:
        Bool {

        guard let original =
            profileBeingEdited
        else {
            return false
        }

        let editedName =
            profileName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let originalName =
            original.name
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let editedModel =
            modelID
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let originalModel =
            original.modelID
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let newKey =
            apiKeyDraft
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        return
            editedName != originalName
            || provider != original.provider
            || editedModel != originalModel
            || !newKey.isEmpty
    }

    private var modificationConfirmationMessage:
        String {

        switch editorMode {
        case .editingActive:
            return language.text(
                "确定保存对当前配置的修改吗？保存成功后将立即生效。",
                "現在の設定への変更を保存しますか？保存後すぐに反映されます。"
            )

        case .editingSaved:
            return language.text(
                "确定保存对此列表配置的修改吗？保存后只更新配置列表，不会立即生效。",
                "一覧設定への変更を保存しますか？保存後は一覧のみ更新され、すぐには反映されません。"
            )

        case .creating:
            return language.text(
                "确定保存此新配置吗？",
                "この新しい設定を保存しますか？"
            )

        case nil:
            return ""
        }
    }

    private func requestSaveEditor() {
        guard let editorMode else {
            return
        }

        switch editorMode {
        case .creating:
            // New profile is not a modification.
            saveEditor()

        case .editingActive,
             .editingSaved:
            if hasEditedConfigurationChanges {
                showSaveConfirmation = true
            } else {
                // Nothing changed: simply close the editor.
                closeEditor()

                statusMessage =
                    language.text(
                        "没有修改内容。",
                        "変更はありません。"
                    )
            }
        }
    }

    // MARK: - Save editor

    private func saveEditor() {
        guard let editorMode else {
            return
        }

        let trimmedName =
            profileName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedName.isEmpty else {
            statusMessage = language.text(
                "请输入配置名称。",
                "設定名を入力してください。"
            )
            return
        }

        let trimmedModel =
            modelID.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedModel.isEmpty else {
            statusMessage = language.text(
                "请输入模型 ID。",
                "モデルIDを入力してください。"
            )
            return
        }

        let draftKey =
            apiKeyDraft.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        switch editorMode {
        case .editingActive(let profileID):
            saveExistingProfile(
                id: profileID,
                name: trimmedName,
                model: trimmedModel,
                draftKey: draftKey,
                applyImmediately: true
            )

        case .editingSaved(let profileID):
            saveExistingProfile(
                id: profileID,
                name: trimmedName,
                model: trimmedModel,
                draftKey: draftKey,
                applyImmediately: false
            )

        case .creating:
            saveNewProfile(
                name: trimmedName,
                model: trimmedModel,
                draftKey: draftKey
            )
        }
    }

    private func saveExistingProfile(
        id profileID: UUID,
        name: String,
        model: String,
        draftKey: String,
        applyImmediately: Bool
    ) {
        guard
            let current = savedProfiles.first(
                where: {
                    $0.id == profileID
                }
            )
        else {
            return
        }

        let isCurrentlyActive =
            current.id == activeProfileID

        if applyImmediately
            && !isCurrentlyActive {
            statusMessage = language.text(
                "当前配置状态已经变化，请重新进入编辑。",
                "現在の設定状態が変更されています。編集をやり直してください。"
            )
            return
        }

        if !applyImmediately
            && isCurrentlyActive {
            statusMessage = language.text(
                "该配置已经是当前配置，请使用“编辑当前配置”。",
                "この設定は現在使用中です。「現在の設定を編集」を使用してください。"
            )
            return
        }

        do {
            // Key belongs only to THIS profile.
            // Keep a copy only for rollback if a new Key
            // is being written during this save.
            let oldSecret =
                try credentialStore.read(
                    account:
                        current
                            .credentialAccount
                )

            // Empty draft is valid:
            // keep whatever this profile currently has.
            //
            // It is also valid for oldSecret to be nil.
            if !draftKey.isEmpty {
                try credentialStore.save(
                    draftKey,
                    account:
                        current
                            .credentialAccount
                )
            }

            let updated =
                AIConfigurationProfile(
                    id: current.id,
                    name: name,
                    provider: provider,
                    modelID: model,
                    credentialAccount:
                        current
                            .credentialAccount
                )

            do {
                try profileStore.save(
                    updated
                )
            } catch {
                // Roll back only if this save changed
                // THIS profile's Key.
                if !draftKey.isEmpty {
                    if let oldSecret {
                        try? credentialStore.save(
                            oldSecret,
                            account:
                                current
                                    .credentialAccount
                        )
                    } else {
                        try? credentialStore.delete(
                            account:
                                current
                                    .credentialAccount
                        )
                    }
                }

                throw error
            }

            // Only editing the active configuration
            // updates the runtime configuration.
            if applyImmediately {
                profileStore.setActiveProfile(
                    id: updated.id
                )

                try configurationStore.save(
                    AIProviderConfiguration(
                        provider:
                            updated.provider,
                        modelID:
                            updated.modelID
                    )
                )

                activeProfileID =
                    updated.id
            }

            savedProfiles =
                profileStore.profiles()

            selectedProfileID =
                updated.id

            connectionStatus =
                .untested

            // Successful save ALWAYS closes editor,
            // whether a Key exists or not.
            closeEditor()

            statusMessage =
                applyImmediately
                ? language.text(
                    "当前 AI 配置「\(updated.name)」已保存并立即生效。",
                    "現在のAI設定「\(updated.name)」を保存し、すぐに反映しました。"
                )
                : language.text(
                    "AI 配置「\(updated.name)」已保存。当前 AI 配置没有改变。",
                    "AI設定「\(updated.name)」を保存しました。現在のAI設定は変更されていません。"
                )

        } catch {
            statusMessage =
                language.text(
                    "无法保存 AI 配置。",
                    "AI設定を保存できませんでした。"
                )
        }
    }

    private func saveNewProfile(
        name: String,
        model: String,
        draftKey: String
    ) {
        let profile =
            AIConfigurationProfile(
                name: name,
                provider: provider,
                modelID: model
            )

        do {
            // Key is optional.
            // If supplied, save only into THIS
            // profile's unique credential account.
            if !draftKey.isEmpty {
                try credentialStore.save(
                    draftKey,
                    account:
                        profile
                            .credentialAccount
                )
            }

            do {
                try profileStore.save(
                    profile
                )
            } catch {
                if !draftKey.isEmpty {
                    try? credentialStore.delete(
                        account:
                            profile
                                .credentialAccount
                    )
                }

                throw error
            }

            savedProfiles =
                profileStore.profiles()

            selectedProfileID =
                profile.id

            connectionStatus =
                .untested

            closeEditor()

            statusMessage =
                language.text(
                    "AI 配置「\(profile.name)」已保存到配置列表。需要点击“加载此配置”后才会生效。",
                    "AI設定「\(profile.name)」を一覧に保存しました。「この設定を読み込む」を押した後に有効になります。"
                )

        } catch {
            statusMessage =
                language.text(
                    "无法保存新的 AI 配置。",
                    "新しいAI設定を保存できませんでした。"
                )
        }
    }

    // MARK: - Edit selected

    private func editSelectedProfile() {
        guard let profile =
            selectedProfileForDeletion
        else {
            return
        }

        guard profile.id != activeProfileID else {
            statusMessage = language.text(
                "这是当前正在使用的配置，请使用上方“编辑当前 AI 配置”。",
                "これは現在使用中の設定です。上の「現在のAI設定を編集」を使用してください。"
            )
            return
        }

        editorMode = .editingSaved(
            profile.id
        )
        originalEditingProvider =
            profile.provider

        profileName = profile.name
        provider = profile.provider

        let storedModel =
            profile.modelID
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        modelID =
            storedModel.isEmpty
            ? defaultModelID(
                for: profile.provider
            )
            : storedModel

        apiKeyDraft = ""

        statusMessage = nil
        connectionStatus = .untested

        refreshCredentialState()
    }

    // MARK: - Delete

    private func deleteSelectedProfile() {
        guard let profile =
            selectedProfileForDeletion
        else {
            return
        }

        let wasActive =
            profile.id == activeProfileID

        do {
            try credentialStore.delete(
                account:
                    profile.credentialAccount
            )

            try profileStore.delete(
                id: profile.id
            )

            savedProfiles =
                profileStore.profiles()

            activeProfileID =
                profileStore.activeProfileID()

            selectedProfileID =
                activeProfileID

            closeEditor()
            connectionStatus = .untested

            if let active =
                profileStore.activeProfile() {
                provider =
                    active.provider
                modelID =
                    active.modelID
            } else {
                profileName = ""
                modelID = ""
            }

            refreshCredentialState()

            statusMessage =
                wasActive
                ? language.text(
                    "当前 AI 配置「\(profile.name)」已删除。请手动加载另一个配置后再使用 AI。",
                    "現在のAI設定「\(profile.name)」を削除しました。別の設定を手動で読み込んでください。"
                )
                : language.text(
                    "AI 配置「\(profile.name)」已删除。",
                    "AI設定「\(profile.name)」を削除しました。"
                )

        } catch {
            statusMessage =
                language.text(
                    "无法删除 AI 配置。",
                    "AI設定を削除できませんでした。"
                )
        }
    }

    // MARK: - Activate

    private func activateSelectedProfile() {
        guard
            let selectedProfileID,
            let profile =
                savedProfiles.first(
                    where: {
                        $0.id
                            == selectedProfileID
                    }
                )
        else {
            return
        }

        do {
            profileStore.setActiveProfile(
                id: profile.id
            )

            try configurationStore.save(
                AIProviderConfiguration(
                    provider:
                        profile.provider,
                    modelID:
                        profile.modelID
                )
            )

            activeProfileID = profile.id
            closeEditor()

            connectionStatus = .untested
            refreshCredentialState()

            statusMessage = language.text(
                "已加载 AI 配置「\(profile.name)」。",
                "AI設定「\(profile.name)」を読み込みました。"
            )
        } catch {
            statusMessage = language.text(
                "无法加载 AI 配置。",
                "AI設定を読み込めませんでした。"
            )
        }
    }

    // MARK: - Credential

    private func refreshCredentialState() {
        do {
            if let profileID =
                editorMode?.profileID,
               let profile = savedProfiles.first(
                    where: {
                        $0.id == profileID
                    }
               ) {
                hasStoredCredential =
                    try credentialStore.read(
                        account:
                            profile.credentialAccount
                    ) != nil
                return
            }

            guard let profile =
                activeProfile
            else {
                hasStoredCredential = false
                return
            }

            guard let secret =
                try credentialStore.read(
                    account:
                        profile
                            .credentialAccount
                )
            else {
                hasStoredCredential = false
                return
            }

            hasStoredCredential =
                !secret
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
                    .isEmpty
        } catch {
            hasStoredCredential = false
        }
    }

    private func activeSecret() throws -> String {
        guard let profile = activeProfile
        else {
            throw AIProviderError
                .missingConfiguration(
                    "AI profile"
                )
        }

        guard
            let stored =
                try credentialStore.read(
                    account:
                        profile
                            .credentialAccount
                ),
            !stored.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            ).isEmpty
        else {
            throw AIProviderError
                .missingConfiguration(
                    "\(profile.provider.displayName) API key"
                )
        }

        return stored
    }

    // MARK: - Connection test

    @MainActor
    private func testConnection() async {
        guard let profile = activeProfile
        else {
            connectionStatus = .failed
            statusMessage = language.text(
                "没有当前 AI 配置。",
                "現在のAI設定がありません。"
            )
            return
        }

        isTestingConnection = true
        connectionStatus = .testing
        statusMessage = nil

        defer {
            isTestingConnection = false
        }

        do {
            let testProvider =
                try AIProviderFactory.makeProvider(
                    configuration:
                        AIProviderConfiguration(
                            provider:
                                profile.provider,
                            modelID:
                                profile.modelID
                        ),
                    secret:
                        try activeSecret()
                )

            let response =
                try await testProvider.complete(
                    request:
                        AICompletionRequest(
                            systemPrompt:
                                "Return the requested JSON only.",
                            userPrompt:
                                "Set ok to true.",
                            responseSchemaName:
                                "connection_probe",
                            responseSchemaJSON:
                                """
                                {
                                  "type": "object",
                                  "properties": {
                                    "ok": {
                                      "type": "boolean"
                                    }
                                  },
                                  "required": ["ok"],
                                  "additionalProperties": false
                                }
                                """
                        )
                )

            guard
                let data =
                    response.text.data(
                        using: .utf8
                    ),
                let probe =
                    try? JSONDecoder()
                        .decode(
                            AIConnectionProbe.self,
                            from: data
                        ),
                probe.ok
            else {
                throw AIProviderError
                    .invalidResponse
            }

            connectionStatus = .success

            statusMessage = language.text(
                "连接成功：\(response.providerID) · \(response.modelID)",
                "接続成功：\(response.providerID) · \(response.modelID)"
            )
        } catch let error as AIProviderError {
            connectionStatus = .failed

            switch error {
            case let .missingConfiguration(field):
                statusMessage = language.text(
                    "AI 配置不完整：\(field)。",
                    "AI設定が不完全です：\(field)。"
                )

            case let .http(statusCode, _):
                if statusCode == 401
                    || statusCode == 403 {
                    statusMessage =
                        language.text(
                            "AI 身份验证失败，请检查 API Key。",
                            "AI認証に失敗しました。API Keyを確認してください。"
                        )
                } else {
                    statusMessage =
                        language.text(
                            "AI Provider 返回 HTTP \(statusCode)。",
                            "AI Provider HTTP \(statusCode)。"
                        )
                }

            case .refused:
                statusMessage = language.text(
                    "AI Provider 拒绝了连接测试。",
                    "AI Providerが接続テストを拒否しました。"
                )

            case .incomplete:
                statusMessage = language.text(
                    "AI 连接测试输出未完成。",
                    "AI接続テストの出力が完了しませんでした。"
                )

            case .invalidResponse,
                 .decodingFailed:
                statusMessage = language.text(
                    "AI 返回的数据格式无效。",
                    "AIの応答形式が無効です。"
                )
            }
        } catch {
            connectionStatus = .failed

            statusMessage = language.text(
                "AI 连接测试失败。",
                "AI接続テストに失敗しました。"
            )
        }
    }

    // MARK: - Helpers

    private func defaultModelID(
        for provider: AIProviderKind
    ) -> String {
        let stored =
            configurationStore.modelID(
                for: provider
            )

        if !stored.isEmpty {
            return stored
        }

        switch provider {
        case .deepSeek:
            return "deepseek-flash"

        case .kimi:
            return "kimi-k2.6"

        case .openAI,
             .anthropic:
            return ""
        }
    }

    private var connectionStatusText: String {
        switch connectionStatus {
        case .untested:
            return language.text(
                "未测试",
                "未テスト"
            )

        case .testing:
            return language.text(
                "测试中…",
                "テスト中…"
            )

        case .success:
            return language.text(
                "连接成功",
                "接続成功"
            )

        case .failed:
            return language.text(
                "连接失败",
                "接続失敗"
            )
        }
    }

    private var connectionStatusColor: Color {
        switch connectionStatus {
        case .untested,
             .testing:
            return .secondary

        case .success:
            return .green

        case .failed:
            return .red
        }
    }
}

private enum AIConfigurationEditorMode:
    Equatable {
    case editingActive(UUID)
    case editingSaved(UUID)
    case creating

    var profileID: UUID? {
        switch self {
        case .editingActive(let id),
             .editingSaved(let id):
            return id
        case .creating:
            return nil
        }
    }

    var isEditingExistingProfile: Bool {
        profileID != nil
    }
}

private enum AIConnectionStatus {
    case untested
    case testing
    case success
    case failed
}

private struct AIConnectionProbe: Decodable {
    let ok: Bool
}
