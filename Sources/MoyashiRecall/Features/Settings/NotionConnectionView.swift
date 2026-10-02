import SwiftUI
import SwiftData

public struct NotionConnectionView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @AppStorage("notionRootPageID")
    private var legacyRootPageID = ""

    @State private var profileName = ""
    @State private var tokenDraft = ""

    @State private var rootPageID = ""
    @State private var rootPageTitle = ""

    @State private var availableChildPages:
        [NotionPageSummary] = []

    @State private var selectedSourceIDs =
        Set<String>()

    @State private var activeProfile:
        NotionConfigurationProfile?

    @State private var hasStoredToken = false
    @State private var isWorking = false
    @State private var statusMessage: String?

    @State private var connectionStatus:
        NotionConnectionStatus = .unconfigured

    @State private var connectionDetail: String?

    @State private var lastSyncState:
        NotionSyncState?

    @State private var showDeleteConfirmation =
        false

    private let credentialStore =
        KeychainCredentialStore()

    private let profileStore =
        NotionConfigurationProfileStore()

    public init() {}

    public var body: some View {
        Form {
            currentConnectionSection
            editProfileSection
            deleteProfileSection

            if let statusMessage {
                Section {
                    HStack(spacing: 10) {
                        if isWorking {
                            ProgressView()
                        }

                        Text(statusMessage)
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle(
            language.text(
                "Notion 连接",
                "Notion接続"
            )
        )
        .onAppear {
            migrateLegacyConfigurationIfNeeded()
            loadCurrentProfile()
            loadLastSyncState()
        }
        .task(id: activeProfile?.id) {
            await testConnection(
                showMessage: false
            )
        }
        .alert(
            language.text(
                "删除当前配置？",
                "現在の設定を削除しますか？"
            ),
            isPresented: $showDeleteConfirmation
        ) {
            Button(
                language.text(
                    "删除",
                    "削除"
                ),
                role: .destructive
            ) {
                deleteCurrentProfile()
            }

            Button(
                language.text(
                    "取消",
                    "キャンセル"
                ),
                role: .cancel
            ) {}
        } message: {
            Text(
                language.text(
                    "删除后将清除当前 Profile、Token、Root Page、学习源选择以及该 Profile 对应的本地 Notion 学习资料。Notion 网站上的原始页面不会被删除。此操作不可撤销。",
                    "削除すると、現在のProfile、Token、Root Page、学習ソース選択、およびローカルNotion学習データが消去されます。Notion上の元ページは削除されません。"
                )
            )
        }
    }

    // MARK: - Section 1

    private var currentConnectionSection: some View {
        Section {
            if let profile = activeProfile {
                LabeledContent(
                    language.text(
                        "Profile",
                        "Profile"
                    ),
                    value: profile.name
                )

                LabeledContent(
                    language.text(
                        "Root Page",
                        "Root Page"
                    ),
                    value:
                        profile.rootPageTitle.isEmpty
                        ? "—"
                        : profile.rootPageTitle
                )

                HStack {
                    Text(
                        language.text(
                            "连接状态",
                            "接続状態"
                        )
                    )

                    Spacer()

                    Circle()
                        .fill(connectionStatusColor)
                        .frame(
                            width: 10,
                            height: 10
                        )

                    Text(connectionStatusText)
                        .foregroundStyle(
                            connectionStatusColor
                        )
                }

                if let connectionDetail,
                   !connectionDetail.isEmpty {
                    LabeledContent(
                        language.text(
                            "原因",
                            "理由"
                        ),
                        value: connectionDetail
                    )
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                }

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    Text(
                        language.text(
                            "当前学习源",
                            "現在の学習ソース"
                        )
                    )
                    .font(.subheadline)

                    if profile.selectedSources.isEmpty {
                        Text(
                            language.text(
                                "尚未选择学习源。",
                                "学習ソースが選択されていません。"
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(
                            AppTheme.muted
                        )
                    } else {
                        ForEach(
                            profile.selectedSources
                        ) { source in
                            HStack(spacing: 8) {
                                Image(
                                    systemName:
                                        "checkmark.circle.fill"
                                )
                                .foregroundStyle(
                                    AppTheme.accent
                                )

                                Text(source.title)
                            }
                        }
                    }
                }

                if let lastSyncState {
                    LabeledContent(
                        language.text(
                            "最近同步",
                            "最終同期"
                        ),
                        value:
                            lastSyncState
                                .lastSyncedAt
                                .formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                    )
                }

                HStack {
                    Button {
                        Task {
                            await testConnection(
                                showMessage: true
                            )
                        }
                    } label: {
                        Label(
                            language.text(
                                "测试连接",
                                "接続テスト"
                            ),
                            systemImage: "network"
                        )
                    }

                    Spacer()

                    Button {
                        Task {
                            await syncSelectedSources()
                        }
                    } label: {
                        Label(
                            language.text(
                                "同步已选页面",
                                "選択ページを同期"
                            ),
                            systemImage:
                                "arrow.triangle.2.circlepath"
                        )
                    }
                    .disabled(
                        profile.selectedSources.isEmpty
                        || isWorking
                    )
                }
            } else {
                HStack {
                    Circle()
                        .fill(Color.secondary)
                        .frame(
                            width: 10,
                            height: 10
                        )

                    Text(
                        language.text(
                            "尚未配置 Notion",
                            "Notionは未設定です"
                        )
                    )
                }

                Text(
                    language.text(
                        "请在下面填写 Profile、Token，并连接 Learning Home。",
                        "下でProfile、Tokenを設定し、Learning Homeに接続してください。"
                    )
                )
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
            }
        } header: {
            Text(
                language.text(
                    "当前 Notion 连接",
                    "現在のNotion接続"
                )
            )
        }
    }

    // MARK: - Section 2

    private var editProfileSection: some View {
        Section {
            TextField(
                language.text(
                    "Profile 名称",
                    "Profile名"
                ),
                text: $profileName
            )

            SecureField(
                language.text(
                    "更新 Notion Token",
                    "Notion Tokenを更新"
                ),
                text: $tokenDraft
            )

            HStack {
                Text(
                    language.text(
                        "凭证状态",
                        "認証情報"
                    )
                )

                Spacer()

                Text(
                    hasStoredToken
                    ? language.text(
                        "已安全保存",
                        "保存済み"
                    )
                    : language.text(
                        "未保存",
                        "未保存"
                    )
                )
                .foregroundStyle(AppTheme.muted)
            }

            Button {
                updateToken()
            } label: {
                Label(
                    language.text(
                        "更新 Token",
                        "Tokenを更新"
                    ),
                    systemImage: "key"
                )
            }
            .disabled(
                tokenDraft
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
            )

            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                HStack {
                    Text(
                        language.text(
                            "Learning Home",
                            "Learning Home"
                        )
                    )

                    Spacer()

                    if !rootPageTitle.isEmpty {
                        Text(rootPageTitle)
                            .foregroundStyle(
                                AppTheme.muted
                            )
                    }
                }

                if !rootPageID.isEmpty {
                    Text(rootPageID)
                        .font(.caption2)
                        .foregroundStyle(
                            AppTheme.muted
                        )
                        .lineLimit(1)
                }

                Button {
                    Task {
                        await findExactLearningHome()
                    }
                } label: {
                    Label(
                        language.text(
                            "重新查找 Learning Home",
                            "Learning Homeを再検索"
                        ),
                        systemImage: "magnifyingglass"
                    )
                }
                .disabled(isWorking)
            }

            Button {
                Task {
                    await loadDirectChildPages()
                }
            } label: {
                Label(
                    language.text(
                        "刷新 Learning Home 一级页面",
                        "Learning Home直下ページを更新"
                    ),
                    systemImage: "list.bullet"
                )
            }
            .disabled(
                rootPageID.isEmpty
                || isWorking
            )

            if !availableChildPages.isEmpty {
                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    Text(
                        language.text(
                            "选择学习源",
                            "学習ソースを選択"
                        )
                    )
                    .font(.subheadline)

                    ForEach(
                        availableChildPages,
                        id: \.id
                    ) { page in
                        Toggle(
                            isOn: Binding(
                                get: {
                                    selectedSourceIDs
                                        .contains(page.id)
                                },
                                set: { value in
                                    if value {
                                        selectedSourceIDs
                                            .insert(page.id)
                                    } else {
                                        selectedSourceIDs
                                            .remove(page.id)
                                    }
                                }
                            )
                        ) {
                            Text(page.title)
                        }
                    }
                }
            }

            Button {
                saveCurrentProfile()
            } label: {
                Label(
                    language.text(
                        "保存当前配置",
                        "現在の設定を保存"
                    ),
                    systemImage:
                        "square.and.arrow.down"
                )
            }
        } header: {
            Text(
                language.text(
                    "编辑当前 Profile",
                    "現在のProfileを編集"
                )
            )
        } footer: {
            Text(
                language.text(
                    "Learning Home 是唯一根页面；其一级子页面可以多选作为学习源。Token 仅保存在 Apple Keychain。",
                    "Learning Homeは唯一のルートページで、その直下ページを複数選択できます。TokenはApple Keychainのみに保存されます。"
                )
            )
        }
    }

    // MARK: - Section 3

    @ViewBuilder
    private var deleteProfileSection: some View {
        if activeProfile != nil {
            Section {
                Button(
                    role: .destructive
                ) {
                    showDeleteConfirmation = true
                } label: {
                    Label(
                        language.text(
                            "删除当前配置",
                            "現在の設定を削除"
                        ),
                        systemImage: "trash"
                    )
                }
            } header: {
                Text(
                    language.text(
                        "删除当前配置",
                        "現在の設定を削除"
                    )
                )
            }
        }
    }

    // MARK: - Profile

    private func loadCurrentProfile() {
        activeProfile =
            profileStore.activeProfile()

        guard let profile = activeProfile
        else {
            clearScreen()
            return
        }

        profileName = profile.name
        rootPageID = profile.rootPageID
        rootPageTitle =
            profile.rootPageTitle

        selectedSourceIDs = Set(
            profile.selectedSources.map(\.id)
        )

        availableChildPages =
            profile.selectedSources.map {
                NotionPageSummary(
                    id: $0.id,
                    title: $0.title,
                    url: nil,
                    lastEditedAt: nil
                )
            }

        refreshCredentialState()
    }

    private func saveCurrentProfile() {
        let name =
            profileName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !name.isEmpty else {
            statusMessage = language.text(
                "请输入 Profile 名称。",
                "Profile名を入力してください。"
            )
            return
        }

        guard !rootPageID.isEmpty else {
            statusMessage = language.text(
                "请先连接正确的 Learning Home。",
                "正しいLearning Homeに接続してください。"
            )
            return
        }

        do {
            let existing = activeProfile

            let id = existing?.id ?? UUID()

            let account =
                existing?.credentialAccount
                ?? "notion-profile-\(id.uuidString)"

            if existing == nil {
                let token =
                    tokenDraft
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )

                guard !token.isEmpty else {
                    throw NotionConnectionUIError
                        .missingToken
                }

                try credentialStore.save(
                    token,
                    account: account
                )
            }

            let selectedSources =
                availableChildPages
                    .filter {
                        selectedSourceIDs
                            .contains($0.id)
                    }
                    .map {
                        NotionSelectedSource(
                            id: $0.id,
                            title: $0.title
                        )
                    }

            let profile =
                NotionConfigurationProfile(
                    id: id,
                    name: name,
                    rootPageID: rootPageID,
                    rootPageTitle:
                        rootPageTitle.isEmpty
                        ? "Learning Home"
                        : rootPageTitle,
                    selectedSources:
                        selectedSources,
                    credentialAccount: account
                )

            try profileStore.save(profile)

            profileStore.setActiveProfile(
                id: profile.id
            )

            legacyRootPageID =
                profile.rootPageID

            activeProfile = profile

            tokenDraft = ""

            refreshCredentialState()

            connectionStatus = .unconfigured

            statusMessage = language.text(
                "当前 Notion 配置已保存。",
                "現在のNotion設定を保存しました。"
            )

            Task {
                await testConnection(
                    showMessage: false
                )
            }
        } catch {
            statusMessage =
                connectionErrorMessage(error)
        }
    }

    private func updateToken() {
        let token =
            tokenDraft.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !token.isEmpty else {
            return
        }

        do {
            let profile =
                activeProfile

            let account: String

            if let profile {
                account =
                    profile.credentialAccount
            } else {
                statusMessage = language.text(
                    "请先保存 Profile 基本信息。",
                    "先にProfile基本情報を保存してください。"
                )
                return
            }

            try credentialStore.save(
                token,
                account: account
            )

            tokenDraft = ""

            refreshCredentialState()

            connectionStatus = .unconfigured

            statusMessage = language.text(
                "Token 已安全更新。",
                "Tokenを安全に更新しました。"
            )

            Task {
                await testConnection(
                    showMessage: false
                )
            }
        } catch {
            statusMessage = language.text(
                "无法更新 Token。",
                "Tokenを更新できませんでした。"
            )
        }
    }

    // MARK: - Learning Home

    @MainActor
    private func findExactLearningHome() async {
        isWorking = true

        statusMessage = language.text(
            "正在查找 Learning Home…",
            "Learning Homeを検索中…"
        )

        defer {
            isWorking = false
        }

        do {
            let client =
                NotionAPIClient(
                    token: try workingToken()
                )

            let results =
                try await client.searchPages(
                    query: "Learning Home"
                )

            let exactMatches =
                results.filter {
                    $0.title
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .localizedCaseInsensitiveCompare(
                            "Learning Home"
                        )
                    == .orderedSame
                }

            guard exactMatches.count == 1,
                  let page = exactMatches.first
            else {
                statusMessage =
                    language.text(
                        "无法唯一定位 Learning Home。找到 \(exactMatches.count) 个同名页面。",
                        "Learning Homeを一意に特定できません。同名ページが\(exactMatches.count)件あります。"
                    )
                return
            }

            rootPageID = page.id
            rootPageTitle = page.title

            availableChildPages = []
            selectedSourceIDs = []

            statusMessage = language.text(
                "已定位正确的 Learning Home。",
                "正しいLearning Homeを特定しました。"
            )

            await loadDirectChildPages()
        } catch {
            statusMessage =
                connectionErrorMessage(error)
        }
    }

    @MainActor
    private func loadDirectChildPages() async {
        guard !rootPageID.isEmpty else {
            return
        }

        isWorking = true

        statusMessage = language.text(
            "正在读取 Learning Home 一级页面…",
            "Learning Home直下ページを取得中…"
        )

        defer {
            isWorking = false
        }

        do {
            let client =
                NotionAPIClient(
                    token: try workingToken()
                )

            let pages =
                try await client.directChildPages(
                    parentID: rootPageID
                )

            availableChildPages = pages

            let validIDs =
                Set(pages.map(\.id))

            selectedSourceIDs =
                selectedSourceIDs
                    .intersection(validIDs)

            statusMessage = language.text(
                "读取完成：找到 \(pages.count) 个一级页面。",
                "取得完了：直下ページが\(pages.count)件見つかりました。"
            )
        } catch {
            statusMessage =
                connectionErrorMessage(error)
        }
    }

    // MARK: - Connection

    @MainActor
    private func testConnection(
        showMessage: Bool
    ) async {
        guard let profile = activeProfile
        else {
            connectionStatus =
                .unconfigured
            return
        }

        connectionStatus = .checking
        connectionDetail = nil

        if showMessage {
            isWorking = true

            statusMessage = language.text(
                "正在测试连接…",
                "接続をテスト中…"
            )
        }

        defer {
            if showMessage {
                isWorking = false
            }
        }

        do {
            let client =
                NotionAPIClient(
                    token: try token(
                        for: profile
                    )
                )

            let page =
                try await client.retrievePage(
                    id: profile.rootPageID
                )

            guard page.title
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .localizedCaseInsensitiveCompare(
                    "Learning Home"
                )
                == .orderedSame
            else {
                connectionStatus =
                    .disconnected

                let message = language.text(
                    "当前 Root Page 不是 Learning Home，请重新查找。",
                    "現在のRoot PageはLearning Homeではありません。再検索してください。"
                )

                connectionDetail = message

                if showMessage {
                    statusMessage = message
                }

                return
            }

            connectionStatus =
                .connected
            connectionDetail = nil

            if showMessage {
                statusMessage =
                    language.text(
                        "连接成功：Learning Home",
                        "接続成功：Learning Home"
                    )
            }
        } catch {
            connectionStatus =
                .disconnected

            let message =
                connectionErrorMessage(error)

            connectionDetail = message

            if showMessage {
                statusMessage = message
            }
        }
    }

    // MARK: - Sync

    @MainActor
    private func syncSelectedSources() async {
        guard let profile = activeProfile
        else {
            return
        }

        guard !profile.selectedSources.isEmpty
        else {
            statusMessage = language.text(
                "请至少选择一个学习源。",
                "学習ソースを1つ以上選択してください。"
            )
            return
        }

        isWorking = true

        statusMessage = language.text(
            "正在同步已选学习源…",
            "選択した学習ソースを同期中…"
        )

        defer {
            isWorking = false
        }

        do {
            let client =
                NotionAPIClient(
                    token: try token(
                        for: profile
                    )
                )

            let repository =
                LearningRepository(
                    context: modelContext
                )

            let service =
                NotionImportService(
                    repository: repository,
                    client: client
                )

            var totalPages = 0
            var inserted = 0
            var updated = 0
            var unchanged = 0
            var deactivated = 0
            var complete = true

            for source
            in profile.selectedSources {
                let report =
                    try await service
                        .syncPageTreeReport(
                            rootID: source.id
                        )

                totalPages +=
                    report.totalPages

                inserted +=
                    report.inserted

                updated +=
                    report.updated

                unchanged +=
                    report.unchanged

                deactivated +=
                    report.deactivated

                complete =
                    complete
                    && report.isComplete
            }

            let report =
                NotionSyncReport(
                    totalPages: totalPages,
                    inserted: inserted,
                    updated: updated,
                    unchanged: unchanged,
                    deactivated: deactivated,
                    isComplete: complete
                )

            let state =
                NotionSyncState(
                    rootPageID:
                        profile.rootPageID,
                    lastSyncedAt: .now,
                    report: report
                )

            try?
                NotionSyncStateStore()
                    .save(state)

            lastSyncState = state

            connectionStatus =
                .connected

            statusMessage =
                language.text(
                    "同步完成：\(profile.selectedSources.count) 个学习源，共 \(totalPages) 个页面。",
                    "同期完了：学習ソース\(profile.selectedSources.count)件、合計\(totalPages)ページ。"
                )
        } catch {
            connectionStatus =
                .disconnected

            statusMessage =
                connectionErrorMessage(error)
        }
    }

    // MARK: - Delete

    private func deleteCurrentProfile() {
        guard let profile = activeProfile
        else {
            return
        }

        let repository =
            LearningRepository(
                context: modelContext
            )

        var roots =
            Set(
                profile.selectedSources
                    .map(\.id)
            )

        if !profile.rootPageID.isEmpty {
            roots.insert(
                profile.rootPageID
            )
        }

        for root in roots {
            _ = try?
                repository
                    .deleteImportedSource(
                        sourceKind: "notion",
                        rootExternalID: root
                    )
        }

        try?
            credentialStore.delete(
                account:
                    profile.credentialAccount
            )

        try?
            profileStore.delete(
                id: profile.id
            )

        try?
            credentialStore.delete(
                account:
                    NotionCredential.tokenAccount
            )

        NotionSyncStateStore().clear()

        legacyRootPageID = ""

        activeProfile = nil
        lastSyncState = nil

        connectionStatus =
            .unconfigured

        clearScreen()

        statusMessage = language.text(
            "当前 Notion 配置已删除，所有设置已清空。",
            "現在のNotion設定を削除し、すべての設定を消去しました。"
        )
    }

    // MARK: - Helpers

    private func refreshCredentialState() {
        do {
            guard let activeProfile
            else {
                hasStoredToken = false
                return
            }

            hasStoredToken =
                try credentialStore.read(
                    account:
                        activeProfile
                            .credentialAccount
                ) != nil
        } catch {
            hasStoredToken = false
        }
    }

    private func workingToken() throws -> String {
        let draft =
            tokenDraft.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !draft.isEmpty {
            return draft
        }

        if let profile = activeProfile {
            return try token(
                for: profile
            )
        }

        if let legacy =
            try credentialStore.read(
                account:
                    NotionCredential
                        .tokenAccount
            ),
           !legacy.isEmpty {
            return legacy
        }

        throw
            NotionConnectionUIError
                .missingToken
    }

    private func token(
        for profile:
            NotionConfigurationProfile
    ) throws -> String {
        guard let value =
            try credentialStore.read(
                account:
                    profile
                        .credentialAccount
            ),
              !value
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
        else {
            throw
                NotionConnectionUIError
                    .missingToken
        }

        return value
    }

    private func clearScreen() {
        profileName = ""
        tokenDraft = ""

        rootPageID = ""
        rootPageTitle = ""

        availableChildPages = []
        selectedSourceIDs = []

        hasStoredToken = false
    }

    private func migrateLegacyConfigurationIfNeeded() {
        guard
            profileStore.profiles().isEmpty
        else {
            return
        }

        do {
            let legacyToken =
                try credentialStore.read(
                    account:
                        NotionCredential
                            .tokenAccount
                )

            let trimmedRoot =
                legacyRootPageID
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            guard
                legacyToken != nil
                || !trimmedRoot.isEmpty
            else {
                return
            }

            let profile =
                NotionConfigurationProfile(
                    name:
                        "Legacy Notion",
                    rootPageID:
                        trimmedRoot,
                    rootPageTitle: "",
                    selectedSources: []
                )

            if let legacyToken,
               !legacyToken.isEmpty {
                try credentialStore.save(
                    legacyToken,
                    account:
                        profile
                            .credentialAccount
                )
            }

            try profileStore.save(
                profile
            )

            profileStore
                .setActiveProfile(
                    id: profile.id
                )
        } catch {
        }
    }

    private func loadLastSyncState() {
        lastSyncState =
            try?
                NotionSyncStateStore()
                    .load()
    }

    private var connectionStatusText:
        String {
        switch connectionStatus {
        case .unconfigured:
            return language.text(
                "未配置 / 未测试",
                "未設定 / 未テスト"
            )
        case .checking:
            return language.text(
                "检查中",
                "確認中"
            )
        case .connected:
            return language.text(
                "已连接",
                "接続済み"
            )
        case .disconnected:
            return language.text(
                "连接失败",
                "接続失敗"
            )
        }
    }

    private var connectionStatusColor:
        Color {
        switch connectionStatus {
        case .unconfigured,
             .checking:
            return .secondary
        case .connected:
            return .green
        case .disconnected:
            return .red
        }
    }

    private func connectionErrorMessage(
        _ error: Error
    ) -> String {
        if error
            is NotionConnectionUIError {
            return language.text(
                "请先输入或保存 Notion Token。",
                "Notion Tokenを入力または保存してください。"
            )
        }

        if let apiError =
            error as? NotionAPIError,
           case let .http(
                statusCode,
                _
           ) = apiError {

            switch statusCode {
            case 401:
                return language.text(
                    "Notion Token 无效或已失效（HTTP 401）。",
                    "Notion Tokenが無効または期限切れです（HTTP 401）。"
                )

            case 403:
                return language.text(
                    "当前 Integration 无权访问 Learning Home（HTTP 403）。",
                    "現在のIntegrationにはLearning Homeへのアクセス権がありません（HTTP 403）。"
                )

            case 404:
                return language.text(
                    "找不到当前 Learning Home，或该页面未共享给 Integration（HTTP 404）。",
                    "現在のLearning Homeが見つからないか、Integrationに共有されていません（HTTP 404）。"
                )

            case 429:
                return language.text(
                    "Notion API 请求过于频繁，请稍后重试（HTTP 429）。",
                    "Notion APIのリクエストが多すぎます。しばらくしてから再試行してください（HTTP 429）。"
                )

            case 500...599:
                return language.text(
                    "Notion 服务暂时异常（HTTP \(statusCode)），请稍后重试。",
                    "Notionサービスで一時的な問題が発生しています（HTTP \(statusCode)）。後で再試行してください。"
                )

            default:
                return language.text(
                    "Notion API 请求失败（HTTP \(statusCode)）。",
                    "Notion APIリクエストに失敗しました（HTTP \(statusCode)）。"
                )
            }
        }

        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain {
            return language.text(
                "无法连接 Notion 网络服务（错误码 \(nsError.code)）。",
                "Notionネットワークサービスに接続できません（エラー \(nsError.code)）。"
            )
        }

        return language.text(
            "Notion 连接测试失败。",
            "Notion接続テストに失敗しました。"
        )
    }
}

private enum NotionConnectionStatus {
    case unconfigured
    case checking
    case connected
    case disconnected
}

private enum NotionConnectionUIError:
    Error {
    case missingToken
}
