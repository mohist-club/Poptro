import AppKit
import KeyboardShortcuts
import ServiceManagement
import SwiftUI

enum SettingsDestination: String, CaseIterable, Identifiable {
    case general, shortcuts, services, appearance, about
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .shortcuts: return "keyboard"
        case .services: return "globe"
        case .appearance: return "circle.lefthalf.filled"
        case .about: return "info.circle"
        }
    }

    func title(_ language: InterfaceLanguage) -> String {
        switch self {
        case .general: return PoptroText.value("通用", "General", language: language)
        case .shortcuts: return PoptroText.value("快捷键", "Shortcuts", language: language)
        case .services: return PoptroText.value("服务", "Services", language: language)
        case .appearance: return PoptroText.value("外观", "Appearance", language: language)
        case .about: return PoptroText.value("关于", "About", language: language)
        }
    }
}

struct SettingsView: View {
    @ObservedObject private var preferences = AppPreferencesStore.shared
    @State private var destination: SettingsDestination

    init(initialDestination: SettingsDestination = .general) {
        _destination = State(initialValue: initialDestination)
    }

    private var language: InterfaceLanguage { preferences.values.interfaceLanguage }

    var body: some View {
        VStack(spacing: 0) {
            SafariSettingsToolbar(selection: $destination, language: language)
            Divider()
            Group {
                switch destination {
                case .general: GeneralSettingsView()
                case .shortcuts: ShortcutSettingsView()
                case .services: ServicesSettingsView()
                case .appearance: AppearanceSettingsView()
                case .about: AboutView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background {
            SettingsSurfaceBackground(
                isEnabled: preferences.values.glassEffectEnabled,
                transparency: preferences.values.glassTransparency
            )
                .ignoresSafeArea()
        }
        .frame(minWidth: 836, minHeight: 560)
        .preferredColorScheme(preferences.values.appearanceMode == .dark ? .dark :
            preferences.values.appearanceMode == .light ? .light : nil)
    }
}

private struct SafariSettingsToolbar: View {
    @Binding var selection: SettingsDestination
    let language: InterfaceLanguage

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SettingsDestination.allCases) { destination in
                Button {
                    selection = destination
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: destination.icon)
                            .symbolRenderingMode(.monochrome)
                            .font(.system(size: 22, weight: .regular))
                            .frame(width: 28, height: 25)
                        Text(destination.title(language))
                            .font(.system(size: 11, weight: .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundStyle(selection == destination ? Color.accentColor : Color.secondary)
                    .frame(width: 56, height: 49)
                    .background {
                        if selection == destination {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.76))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.6)
                                }
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(destination.title(language))
                .accessibilityAddTraits(selection == destination ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 7)
        .padding(.bottom, 6)
        .frame(height: 63)
        .background(.bar)
    }
}

private struct SettingsSurfaceBackground: View {
    let isEnabled: Bool
    let transparency: Double

    var body: some View {
        if isEnabled {
            ZStack {
                SettingsMaterialBackground()
                Color(nsColor: .windowBackgroundColor)
                    .opacity(max(0.08, 1 - transparency))
            }
        } else {
            Color(nsColor: .windowBackgroundColor)
        }
    }
}

private struct SettingsMaterialBackground: NSViewRepresentable {

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = .underWindowBackground
        view.isEmphasized = false
    }
}

struct GeneralSettingsView: View {
    @ObservedObject private var preferences = AppPreferencesStore.shared
    @State private var launchAtLogin: Bool
    @State private var accessibilityGranted = PermissionManager.shared.isAccessibilityTrusted
    @State private var launchAtLoginError: String?
    @State private var translationSettings = TranslationSettings.loadCurrent()

    init() { _launchAtLogin = State(initialValue: SMAppService.mainApp.status == .enabled) }
    private var language: InterfaceLanguage { preferences.values.interfaceLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                PreferenceRow(t("开机时启动", "Launch at Login")) {
                    Toggle(t("开启", "On"), isOn: $launchAtLogin)
                        .toggleStyle(.checkbox)
                        .onChange(of: launchAtLogin) { updateLaunchAtLogin($0) }
                }
                PreferenceRow(t("划词翻译快捷键", "Selection Translation Shortcut")) {
                    ShortcutRecorderView(name: .translateSelection)
                        .frame(width: 260)
                }
                if let launchAtLoginError {
                    PreferenceSupportingText(launchAtLoginError, color: .red)
                }

                PreferenceSectionGap()

                PreferenceRow(t("界面语言", "Interface Language")) {
                    Picker("", selection: $preferences.values.interfaceLanguage) {
                        ForEach(InterfaceLanguage.allCases) { Text($0.nativeDisplayName).tag($0) }
                    }
                    .labelsHidden()
                    .frame(width: 260)
                }
                PreferenceRow(t("所需权限", "Required Permission"), alignment: .top) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Label(
                                accessibilityGranted ? t("辅助功能已允许", "Accessibility Allowed") : t("辅助功能未允许", "Accessibility Not Allowed"),
                                systemImage: accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                            )
                            .foregroundStyle(accessibilityGranted ? Color.secondary : Color.orange)
                            Button(t("重新检测", "Recheck")) {
                                accessibilityGranted = PermissionManager.shared.isAccessibilityTrusted
                            }
                            Button(t("前往系统设置…", "Open System Settings…")) {
                                PermissionManager.shared.openSystemPreferencesAccessibilityPane()
                            }
                        }
                        Text(t(
                            "Poptro 只使用辅助功能读取选中的文字并触发快捷键，不会记录或上传你的内容。",
                            "Poptro only uses Accessibility to read selected text and trigger shortcuts. It never records or uploads your content."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                PreferenceSectionGap()

                PreferenceRow(t("默认翻译服务", "Default Translation Service")) {
                    Picker("", selection: defaultProviderBinding) {
                        ForEach(availableProviders) { provider in
                            Text(provider.localizedDisplayName(language: language)).tag(provider)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 260)
                }
                PreferenceRow(t("默认目标语言", "Default Target Language")) {
                    Picker("", selection: primaryLanguageBinding) {
                        ForEach(SupportedLanguage.options, id: \.code) { option in
                            Text(SupportedLanguage.localizedLabel(for: option.code, language: language)).tag(option.code)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 260)
                }
                PreferenceRow(t("自动检查更新", "Automatically Check for Updates")) {
                    Toggle(t("开启", "On"), isOn: $preferences.values.automaticUpdateChecks)
                        .toggleStyle(.checkbox)
                }

                PreferenceSectionGap()

                PreferenceRow(t("帮助与反馈", "Help & Feedback"), alignment: .top) {
                    VStack(alignment: .leading, spacing: 10) {
                        Link("GitHub Issues", destination: URL(string: "https://github.com/mohist-club/Poptro/issues")!)
                        Text(t(
                            "隐私：所有设置仅保存在这台 Mac 上。",
                            "Privacy: all settings are stored only on this Mac."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .controlSize(.regular)
            .frame(maxWidth: 680)
            .padding(.horizontal, 26)
            .padding(.top, 20)
            .padding(.bottom, 22)
        }
        .onAppear {
            accessibilityGranted = PermissionManager.shared.isAccessibilityTrusted
            translationSettings = TranslationSettings.loadCurrent()
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
    private var availableProviders: [TranslationProvider] {
        let providers = translationSettings.availableConfiguredProviders()
        return providers.isEmpty ? [translationSettings.provider] : providers
    }
    private var defaultProviderBinding: Binding<TranslationProvider> {
        Binding(
            get: { translationSettings.provider },
            set: { translationSettings.provider = $0; translationSettings.save() }
        )
    }
    private var primaryLanguageBinding: Binding<String> {
        Binding(
            get: { translationSettings.primaryLanguageCode },
            set: { translationSettings.primaryLanguageCode = $0; translationSettings.save() }
        )
    }
    private func t(_ zh: String, _ en: String) -> String { PoptroText.value(zh, en, language: language) }
}

private struct PreferenceRow<Content: View>: View {
    let label: String
    let alignment: VerticalAlignment
    let content: Content

    init(_ label: String, alignment: VerticalAlignment = .center, @ViewBuilder content: () -> Content) {
        self.label = label
        self.alignment = alignment
        self.content = content()
    }

    var body: some View {
        HStack(alignment: alignment, spacing: 12) {
            Text(label + "：")
                .font(.system(size: 13))
                .frame(width: 220, alignment: .trailing)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 34)
    }
}

private struct PreferenceSectionGap: View {
    var body: some View { Color.clear.frame(height: 12) }
}

private struct PreferenceSupportingText: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color = .secondary) {
        self.text = text
        self.color = color
    }

    var body: some View {
        HStack(spacing: 12) {
            Color.clear.frame(width: 220, height: 1)
            Text(text).font(.caption).foregroundStyle(color)
            Spacer()
        }
        .padding(.top, -5)
    }
}

struct ShortcutSettingsView: View {
    @ObservedObject private var preferences = AppPreferencesStore.shared
    @ObservedObject private var launcher = AppLauncher.shared
    @AppStorage("translateShortcutEnabled") private var translateShortcutEnabled = true
    @State private var addSheet: ShortcutAddSheet?
    private var language: InterfaceLanguage { preferences.values.interfaceLanguage }

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "character.cursor.ibeam").frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t("划词翻译", "Translate Selection"))
                            Text(t("翻译当前选中的文字", "Translate the currently selected text"))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        ShortcutRecorderView(name: .translateSelection).frame(width: 150)
                        Toggle("", isOn: $translateShortcutEnabled)
                            .labelsHidden()
                            .toggleStyle(.checkbox)
                            .onChange(of: translateShortcutEnabled) { HotkeyManager.shared.setTranslationEnabled($0) }
                        Label(t("内置", "Built-in"), systemImage: "lock.fill").font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 38)
                } header: {
                    Text(t("内置快捷键", "Built-in Shortcut"))
                }
                bindingSection(.application, title: t("应用", "Applications"))
                bindingSection(.shortcut, title: t("快捷指令", "Shortcuts"))
                bindingSection(.system, title: t("系统操作", "System Actions"))
                bindingSection(.script, title: t("脚本", "Scripts"))
            }
            .listStyle(.inset)
            Divider()
            HStack {
                Menu {
                    Button { addSheet = .application } label: { Label(t("应用", "Application"), systemImage: "app") }
                    Button { addSheet = .shortcut } label: { Label(t("快捷指令", "Shortcut"), systemImage: "square.stack.3d.up") }
                    Button { addSheet = .system } label: { Label(t("系统操作", "System Action"), systemImage: "gearshape.2") }
                    Button { addSheet = .script } label: { Label(t("脚本", "Script"), systemImage: "terminal") }
                } label: {
                    Label(t("添加快捷键", "Add Shortcut"), systemImage: "plus")
                }
                Spacer()
                Text(t("所有快捷键均可随时修改。", "All shortcuts can be changed at any time."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
        .sheet(item: $addSheet) { sheet in
            switch sheet {
            case .application: AppPickerView(isPresented: sheetBinding)
            case .shortcut: ShortcutPickerView(isPresented: sheetBinding)
            case .system: SystemActionPickerView(isPresented: sheetBinding)
            case .script: ScriptEditorView(isPresented: sheetBinding)
            }
        }
    }

    @ViewBuilder private func bindingSection(_ kind: ShortcutActionKind, title: String) -> some View {
        let items = launcher.bindings(of: kind)
        if !items.isEmpty {
            Section {
                ForEach(items) { binding in bindingRow(binding) }
            } header: {
                Text(title)
            }
        }
    }

    private func bindingRow(_ binding: LaunchBinding) -> some View {
        HStack(spacing: 10) {
            Group {
                if binding.actionKind == .application {
                    Image(nsImage: launcher.icon(forAppPath: binding.appBundlePath)).resizable()
                } else {
                    Image(systemName: actionIcon(binding)).resizable().scaledToFit().foregroundStyle(.secondary)
                }
            }
            .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(binding.appName)
                Text(actionSubtitle(binding)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            ShortcutRecorderView(name: KeyboardShortcuts.Name(binding.hotkeyName)).frame(width: 150)
            Toggle("", isOn: Binding(
                get: { launcher.bindings.first(where: { $0.id == binding.id })?.isEnabled ?? false },
                set: { launcher.setEnabled($0, for: binding) }
            )).labelsHidden().toggleStyle(.checkbox)
            Button(role: .destructive) { launcher.removeBinding(binding) } label: { Image(systemName: "minus.circle") }
                .buttonStyle(.borderless).help(t("删除快捷键", "Remove Shortcut"))
        }
        .frame(minHeight: 34)
    }

    private var sheetBinding: Binding<Bool> {
        Binding(get: { addSheet != nil }, set: { if !$0 { addSheet = nil } })
    }
    private func actionIcon(_ binding: LaunchBinding) -> String {
        switch binding.actionKind {
        case .application: return "app"
        case .shortcut: return "square.stack.3d.up"
        case .system: return "gearshape.2"
        case .script: return "terminal"
        }
    }
    private func actionSubtitle(_ binding: LaunchBinding) -> String {
        switch binding.actionKind {
        case .application: return t("打开应用", "Open Application")
        case .shortcut: return t("运行快捷指令", "Run Shortcut")
        case .system: return t("执行系统操作", "Run System Action")
        case .script:
            switch binding.scriptKind ?? .shell {
            case .shell: return "Shell"
            case .appleScript: return "AppleScript"
            case .javaScript: return "JavaScript for Automation"
            }
        }
    }
    private func t(_ zh: String, _ en: String) -> String { PoptroText.value(zh, en, language: language) }
}

private enum ShortcutAddSheet: String, Identifiable {
    case application, shortcut, system, script
    var id: String { rawValue }
}

struct AppPickerView: View {
    @ObservedObject private var preferences = AppPreferencesStore.shared
    @Binding var isPresented: Bool
    @State private var apps: [(name: String, path: String)] = []
    @State private var searchText = ""
    private var language: InterfaceLanguage { preferences.values.interfaceLanguage }
    private var filtered: [(name: String, path: String)] {
        searchText.isEmpty ? apps : apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 12) {
            TextField(t("搜索应用", "Search Apps"), text: $searchText).textFieldStyle(.roundedBorder)
            List(filtered, id: \.path) { app in
                HStack {
                    Image(nsImage: AppLauncher.shared.icon(forAppPath: app.path)).resizable().frame(width: 24, height: 24)
                    Text(app.name); Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    AppLauncher.shared.addBinding(appName: app.name, appBundlePath: app.path)
                    isPresented = false
                }
            }
            HStack { Spacer(); Button(t("取消", "Cancel")) { isPresented = false } }
        }
        .padding(16).frame(width: 420, height: 440)
        .onAppear { apps = AppLauncher.shared.scanInstalledApplications() }
    }
    private func t(_ zh: String, _ en: String) -> String { PoptroText.value(zh, en, language: language) }
}

struct ShortcutPickerView: View {
    @ObservedObject private var preferences = AppPreferencesStore.shared
    @Binding var isPresented: Bool
    @State private var shortcuts: [String] = []
    @State private var errorMessage: String?
    @State private var isLoading = true
    private var language: InterfaceLanguage { preferences.values.interfaceLanguage }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: t("选择快捷指令", "Choose Shortcut"), subtitle: t("从“快捷指令”应用读取。", "Loaded from the Shortcuts app."))
            Divider()
            Group {
                if isLoading { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
                else if let errorMessage {
                    VStack(spacing: 10) {
                        Label(errorMessage, systemImage: "exclamationmark.triangle").foregroundStyle(.secondary)
                        Button(t("重新读取", "Retry")) { load() }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(shortcuts, id: \.self) { name in
                        Label(name, systemImage: "square.stack.3d.up")
                            .contentShape(Rectangle())
                            .onTapGesture { AppLauncher.shared.addShortcut(named: name); isPresented = false }
                    }.listStyle(.inset)
                }
            }
            Divider()
            SheetFooter(isPresented: $isPresented)
        }
        .frame(width: 440, height: 420)
        .onAppear { load() }
    }
    private func load() {
        isLoading = true; errorMessage = nil
        AppLauncher.shared.listShortcuts { result in
            isLoading = false
            switch result { case .success(let values): shortcuts = values; case .failure(let error): errorMessage = error.localizedDescription }
        }
    }
    private func t(_ zh: String, _ en: String) -> String { PoptroText.value(zh, en, language: language) }
}

struct SystemActionPickerView: View {
    @ObservedObject private var preferences = AppPreferencesStore.shared
    @Binding var isPresented: Bool
    private var language: InterfaceLanguage { preferences.values.interfaceLanguage }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: t("选择系统操作", "Choose System Action"), subtitle: t("危险操作会在执行前再次确认。", "Destructive actions always ask for confirmation."))
            Divider()
            List(SystemShortcutAction.allCases) { action in
                Label(actionName(action), systemImage: actionIcon(action))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        AppLauncher.shared.addSystemAction(action, displayName: actionName(action))
                        isPresented = false
                    }
            }.listStyle(.inset)
            Divider()
            SheetFooter(isPresented: $isPresented)
        }
        .frame(width: 440, height: 390)
    }
    private func actionName(_ action: SystemShortcutAction) -> String {
        switch action {
        case .lockScreen: return t("锁定屏幕", "Lock Screen")
        case .sleep: return t("进入睡眠", "Sleep")
        case .emptyTrash: return t("清空废纸篓", "Empty Trash")
        case .logOut: return t("退出登录", "Log Out")
        case .restart: return t("重新启动", "Restart")
        case .shutDown: return t("关机", "Shut Down")
        }
    }
    private func actionIcon(_ action: SystemShortcutAction) -> String {
        switch action {
        case .lockScreen: return "lock"
        case .sleep: return "moon.zzz"
        case .emptyTrash: return "trash"
        case .logOut: return "rectangle.portrait.and.arrow.right"
        case .restart: return "arrow.clockwise"
        case .shutDown: return "power"
        }
    }
    private func t(_ zh: String, _ en: String) -> String { PoptroText.value(zh, en, language: language) }
}

struct ScriptEditorView: View {
    @ObservedObject private var preferences = AppPreferencesStore.shared
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var kind: ShortcutScriptKind = .shell
    @State private var source = ""
    private var language: InterfaceLanguage { preferences.values.interfaceLanguage }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: t("添加脚本", "Add Script"), subtitle: t("脚本仅保存在这台 Mac，并以当前用户身份运行。", "The script stays on this Mac and runs as the current user."))
            Divider()
            Form {
                TextField(t("名称", "Name"), text: $name)
                Picker(t("脚本类型", "Script Type"), selection: $kind) {
                    Text("Shell").tag(ShortcutScriptKind.shell)
                    Text("AppleScript").tag(ShortcutScriptKind.appleScript)
                    Text("JavaScript for Automation").tag(ShortcutScriptKind.javaScript)
                }
                LabeledContent(t("脚本", "Script")) {
                    TextEditor(text: $source)
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 330, height: 190)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(nsColor: .separatorColor), lineWidth: 0.6))
                }
            }
            .formStyle(.columns)
            .padding(18)
            Divider()
            HStack {
                Spacer()
                Button(t("取消", "Cancel")) { isPresented = false }
                Button(t("添加", "Add")) {
                    AppLauncher.shared.addScript(name: name.trimmingCharacters(in: .whitespacesAndNewlines), source: source, kind: kind)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }.padding(12)
        }
        .frame(width: 560, height: 420)
    }
    private func t(_ zh: String, _ en: String) -> String { PoptroText.value(zh, en, language: language) }
}

private struct SheetHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.headline)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
    }
}

private struct SheetFooter: View {
    @ObservedObject private var preferences = AppPreferencesStore.shared
    @Binding var isPresented: Bool
    var body: some View {
        HStack {
            Spacer()
            Button(PoptroText.value(
                "取消", "Cancel", language: preferences.values.interfaceLanguage
            )) { isPresented = false }
        }
        .padding(12)
    }
}

struct ServicesSettingsView: View {
    @ObservedObject private var preferences = AppPreferencesStore.shared
    @State private var settings: TranslationSettings
    @State private var selectedProvider: TranslationProvider
    @State private var apiKeys: [TranslationProvider: String] = [:]
    @State private var discoveredModels: [TranslationProvider: [String]] = [:]
    @State private var benchmarks: [TranslationProvider: ProviderBenchmarkResult] = [:]
    @State private var isLoadingModels = false
    @State private var isBenchmarking = false
    @State private var statusMessage: String?
    @State private var statusIsError = false
    @State private var showSaved = false
    private var language: InterfaceLanguage { preferences.values.interfaceLanguage }

    init() {
        let current = TranslationSettings.loadCurrent()
        _settings = State(initialValue: current)
        _selectedProvider = State(initialValue: current.provider)
    }

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                List(selection: $selectedProvider) {
                    Section(t("翻译服务", "Translation Services")) {
                        ForEach(displayedProviders) { provider in
                            providerRow(provider).tag(provider)
                        }
                    }
                }
                .listStyle(.sidebar)
                Divider()
                HStack {
                    Menu {
                        ForEach(addableProviders) { provider in
                            Button {
                                selectedProvider = provider
                            } label: {
                                Label(providerListName(provider), systemImage: providerIcon(provider))
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .menuStyle(.borderlessButton)
                    .help(t("添加服务", "Add Service"))
                    .disabled(addableProviders.isEmpty)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .frame(height: 34)
            }
            .frame(minWidth: 210, idealWidth: 230, maxWidth: 260)

            VStack(spacing: 0) {
                providerHeader
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                Divider()
                ScrollView {
                    providerForm
                        .frame(width: 520)
                }
                .frame(maxWidth: .infinity)
                Divider()
                HStack(spacing: 12) {
                    if isLoadingModels || isBenchmarking { ProgressView().controlSize(.small) }
                    if let statusMessage {
                        Label(statusMessage, systemImage: statusIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(statusIsError ? .red : .green).lineLimit(2)
                    } else {
                        Text(t("所有配置仅保存在当前 Mac。", "All configuration stays on this Mac."))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(t("保存", "Save")) { persist() }.keyboardShortcut("s", modifiers: .command)
                    if showSaved { Text(t("已保存", "Saved")).font(.caption).foregroundStyle(.green) }
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
            }
            .frame(minWidth: 560)
        }
        .onAppear { loadLocalValues() }
        .onChange(of: selectedProvider) { _ in
            statusMessage = nil
            statusIsError = false
        }
    }

    private func providerRow(_ provider: TranslationProvider) -> some View {
        HStack(spacing: 8) {
            Label(providerListName(provider), systemImage: providerIcon(provider))
                .lineLimit(1)
            Spacer(minLength: 4)
            if provider == settings.provider {
                Image(systemName: "star.fill")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(t("默认服务", "Default Service"))
            }
            Text(providerStatusText(provider))
                .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(.vertical, 3)
    }

    private var providerHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(selectedProvider.localizedDisplayName(language: language))
                    .font(.headline)
                Text(providerDetailSubtitle(selectedProvider))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Label(providerStatusLongText(selectedProvider), systemImage: statusIcon(for: selectedProvider))
                    .font(.caption)
                    .foregroundStyle(statusColor(for: selectedProvider))
                    .lineLimit(1)
            }
            Spacer()
            if selectedProvider == settings.provider {
                Label(t("默认服务", "Default Service"), systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Button(t("设为默认", "Set as Default")) { setDefaultProvider() }
            }
        }
    }

    private func statusIcon(for provider: TranslationProvider) -> String {
        if let result = benchmarks[provider] {
            return result.isSuccessful ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
        }
        if provider.requiresAPIKey, keyBindingValue(provider).isEmpty {
            return "exclamationmark.triangle.fill"
        }
        return "circle.dashed"
    }

    @ViewBuilder private var providerForm: some View {
        Form {
            if selectedProvider != .ollama {
                Section(t("连接", "Connection")) {
                    LabeledContent("API Key") {
                        SecureField("", text: keyBinding(for: selectedProvider))
                            .frame(width: 300)
                    }
                    if selectedProvider == .zhipu {
                        LabeledContent(t("接口地址", "Endpoint"), value: "open.bigmodel.cn/api/paas/v4")
                    } else if selectedProvider == .groq {
                        LabeledContent(t("接口地址", "Endpoint"), value: "api.groq.com/openai/v1")
                    } else if selectedProvider == .google {
                        LabeledContent(t("接口地址", "Endpoint"), value: "generativelanguage.googleapis.com/v1beta")
                    } else if selectedProvider == .deepl {
                        LabeledContent(t("API 类型", "API Type"), value: t("自动识别 Free / Pro", "Detect Free / Pro automatically"))
                    }
                }
            } else {
                Section(t("连接", "Connection")) {
                    LabeledContent(t("服务名称", "Service Name"), value: "Ollama")
                    LabeledContent("Base URL") {
                        TextField("", text: $settings.ollamaBaseURL)
                            .frame(width: 300)
                    }
                    LabeledContent(t("请求超时", "Timeout"), value: t("60 秒", "60 seconds"))
                }
            }

            if selectedProvider != .deepl {
                Section(t("模型", "Model")) {
                    Picker(t("模型", "Model"), selection: selectedModelBinding) {
                        ForEach(modelOptions, id: \.self) { Text($0).tag($0) }
                    }
                    HStack {
                        Button { refreshModels() } label: {
                            Label(t("读取支持的模型", "Load Supported Models"), systemImage: "arrow.clockwise")
                        }
                        .disabled(isLoadingModels || (selectedProvider.requiresAPIKey && keyBindingValue(selectedProvider).isEmpty))
                        Text(t("推荐：", "Recommended: ") + recommendedModel(for: selectedProvider))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Section(t("性能测试记录", "Performance Test")) {
                if let result = benchmarks[selectedProvider], result.isSuccessful {
                    LabeledContent(t("当前模型", "Model"), value: result.model)
                    LabeledContent(t("首字耗时", "Time to First Token"), value: durationText(result.firstTokenSeconds))
                    LabeledContent(t("完整耗时", "Total Time"), value: durationText(result.totalSeconds))
                    LabeledContent(t("输出速度", "Output Speed"), value: speedText(result.charactersPerSecond))
                    Label(
                        t("上次测速：", "Last tested: ") + formattedDate(result.testedAt),
                        systemImage: "checkmark.circle.fill"
                    ).font(.caption).foregroundStyle(.secondary)
                } else if let result = benchmarks[selectedProvider], let error = result.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(.orange)
                } else {
                    Text(t("尚未测速。", "Not tested yet."))
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Button(t("验证并测速", "Verify & Test Speed")) { benchmarkSelectedProvider() }
                        .disabled(isBenchmarking || isLoadingModels)
                    Text(t(
                        "测速会实际发送一段短文本，并消耗少量额度。",
                        "The speed test sends a short translation and uses a small amount of quota."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                }
            }

            Section(t("翻译语言", "Translation Languages")) {
                LabeledContent(t("源语言", "Source Language"), value: t("自动检测", "Auto Detect"))
                Picker(t("目标语言", "Target Language"), selection: $settings.primaryLanguageCode) {
                    ForEach(SupportedLanguage.options, id: \.code) { option in
                        Text(SupportedLanguage.localizedLabel(for: option.code, language: language)).tag(option.code)
                    }
                }
                Picker(t("备用语言", "Secondary Language"), selection: $settings.secondaryLanguageCode) {
                    ForEach(SupportedLanguage.options, id: \.code) { option in
                        Text(SupportedLanguage.localizedLabel(for: option.code, language: language)).tag(option.code)
                    }
                }
            }

            if selectedProvider != .deepl {
                Section(t("高级", "Advanced")) {
                    DisclosureGroup(t("翻译系统提示词", "Translation System Prompt")) {
                        TextEditor(text: $settings.customSystemPrompt)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(minHeight: 130)
                        HStack {
                            Text(t(
                                "只影响 AI 模型的翻译风格与格式。",
                                "Only affects translation style and formatting for AI models."
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Spacer()
                            Button(t("恢复默认", "Restore Default")) {
                                settings.customSystemPrompt = TranslationSettings().customSystemPrompt
                            }
                        }
                    }
                }
            }

        }
        .formStyle(.columns)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var displayedProviders: [TranslationProvider] {
        let configured = settings.configuredProviders
        return TranslationProvider.allCases.filter {
            configured.contains($0) || $0 == selectedProvider || $0 == settings.provider
        }
    }

    private var addableProviders: [TranslationProvider] {
        TranslationProvider.allCases.filter { !displayedProviders.contains($0) }
    }

    private var modelOptions: [String] {
        let current = settings.model(for: selectedProvider)
        var values = discoveredModels[selectedProvider] ?? ProviderModelService.fallbackModels(for: selectedProvider)
        if !current.isEmpty, !values.contains(current) { values.insert(current, at: 0) }
        return values
    }
    private var selectedModelBinding: Binding<String> {
        Binding(get: { settings.model(for: selectedProvider) }, set: { settings.setModel($0, for: selectedProvider) })
    }
    private func keyBinding(for provider: TranslationProvider) -> Binding<String> {
        Binding(get: { apiKeys[provider, default: ""] }, set: { apiKeys[provider] = $0 })
    }
    private func keyBindingValue(_ provider: TranslationProvider) -> String { apiKeys[provider, default: ""] }

    private func loadLocalValues() {
        for provider in TranslationProvider.allCases where provider.requiresAPIKey {
            apiKeys[provider] = KeychainHelper.loadAPIKey(for: provider) ?? ""
        }
        benchmarks = ProviderBenchmarkStore.load()
    }
    private func persist(showConfirmation: Bool = true) {
        for provider in TranslationProvider.allCases where provider.requiresAPIKey {
            let key = apiKeys[provider, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
            if key.isEmpty {
                KeychainHelper.deleteAPIKey(for: provider)
                settings.configuredProviders.remove(provider)
            } else {
                KeychainHelper.saveAPIKey(key, for: provider)
                settings.configuredProviders.insert(provider)
            }
        }
        if selectedProvider == .ollama {
            settings.configuredProviders.insert(.ollama)
        }
        settings.save()
        if showConfirmation {
            showSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { showSaved = false }
        }
    }
    private func setDefaultProvider() {
        settings.provider = selectedProvider
        persist(showConfirmation: false)
        statusIsError = false
        statusMessage = t("已设为默认翻译服务", "Default translation service updated")
    }
    private func refreshModels() {
        persist(showConfirmation: false)
        let provider = selectedProvider
        isLoadingModels = true; statusMessage = t("正在读取模型…", "Loading models…"); statusIsError = false
        Task {
            do {
                let models = try await ProviderModelService.fetchModels(for: provider, settings: settings)
                await MainActor.run {
                    discoveredModels[provider] = models
                    if let first = models.first, !models.contains(settings.model(for: provider)) { settings.setModel(first, for: provider) }
                    isLoadingModels = false
                    statusMessage = t("已读取 \(models.count) 个可用模型", "Loaded \(models.count) available models")
                }
            } catch {
                await MainActor.run { isLoadingModels = false; statusIsError = true; statusMessage = error.localizedDescription }
            }
        }
    }
    private func benchmarkSelectedProvider() {
        persist(showConfirmation: false)
        let provider = selectedProvider
        isBenchmarking = true
        statusIsError = false
        statusMessage = t("正在执行真实翻译测速…", "Running a real translation speed test…")
        ProviderBenchmarkService.run(provider: provider, settings: settings) { result in
            benchmarks[provider] = result
            isBenchmarking = false
            statusIsError = !result.isSuccessful
            // 失败详情已经显示在“性能测试记录”中，底栏不再重复同一条错误。
            statusMessage = result.isSuccessful
                ? t("连接正常，测速完成", "Connected; speed test complete")
                : nil
        }
    }

    private func providerIcon(_ provider: TranslationProvider) -> String {
        switch provider {
        case .zhipu: return "sparkles"
        case .openai: return "brain.head.profile"
        case .deepl: return "character.book.closed"
        case .groq: return "bolt.horizontal.circle"
        case .google: return "g.circle"
        case .ollama: return "desktopcomputer"
        }
    }
    private func providerListName(_ provider: TranslationProvider) -> String {
        switch provider {
        case .zhipu: return t("智谱 GLM", "Zhipu GLM")
        case .openai: return "OpenAI"
        case .deepl: return "DeepL"
        case .groq: return "Groq"
        case .google: return "Google AI"
        case .ollama: return t("本地模型", "Local Model")
        }
    }
    private func recommendedModel(for provider: TranslationProvider) -> String {
        switch provider {
        case .zhipu: return "GLM-4-Flash-250414"
        case .openai: return "GPT-4.1 mini"
        case .deepl: return "DeepL API Free"
        case .groq: return "Qwen 3.8 27B"
        case .google: return "Gemini 3.5 Flash-Lite"
        case .ollama: return "Qwen3 8B"
        }
    }
    private func providerDetailSubtitle(_ provider: TranslationProvider) -> String {
        if provider == .zhipu { return t("免费模型服务", "Free model service") }
        if provider == .groq { return t("高速模型推理服务", "High-speed model inference") }
        if provider == .google { return t("Gemini 模型服务", "Gemini model service") }
        if provider == .ollama { return t("连接本机 Ollama，并读取已经安装的模型。", "Connect to local Ollama and load installed models.") }
        return t("配置服务连接、模型和翻译语言。", "Configure the service connection, model and translation languages.")
    }
    private func providerStatusText(_ provider: TranslationProvider) -> String {
        if let result = benchmarks[provider], result.isSuccessful {
            return durationText(result.firstTokenSeconds ?? result.totalSeconds)
        }
        if let result = benchmarks[provider], result.errorMessage != nil {
            return t("需注意", "Attention")
        }
        if provider.requiresAPIKey, keyBindingValue(provider).isEmpty {
            return t("未配置", "Not configured")
        }
        return t("未测速", "Not tested")
    }
    private func providerStatusLongText(_ provider: TranslationProvider) -> String {
        if let result = benchmarks[provider], result.isSuccessful { return t("连接正常", "Connected") }
        if let result = benchmarks[provider], let error = result.errorMessage { return error }
        if provider.requiresAPIKey, keyBindingValue(provider).isEmpty { return t("尚未配置 API Key", "API Key not configured") }
        return t("等待验证与测速", "Waiting for verification and speed test")
    }
    private func statusColor(for provider: TranslationProvider) -> Color {
        if let result = benchmarks[provider] { return result.isSuccessful ? .green : .orange }
        return .secondary.opacity(0.55)
    }
    private func durationText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.2f %@", value, t("秒", "s"))
    }
    private func speedText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.0f %@", value, t("字符/秒", "chars/s"))
    }
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = language == .chinese ? Locale(identifier: "zh_CN") : Locale(identifier: "en_US")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    private func t(_ zh: String, _ en: String) -> String { PoptroText.value(zh, en, language: language) }
}

struct AppearanceSettingsView: View {
    @ObservedObject private var preferences = AppPreferencesStore.shared
    private var language: InterfaceLanguage { preferences.values.interfaceLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                PreferenceRow(t("外观", "Appearance")) {
                    Picker("", selection: $preferences.values.appearanceMode) {
                        ForEach(PanelAppearanceMode.allCases) {
                            Text($0.localizedName(language: language)).tag($0)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 260)
                }
                PreferenceRow(t("窗口玻璃效果", "Window Glass Effect")) {
                    Toggle(t("开启", "On"), isOn: $preferences.values.glassEffectEnabled)
                        .toggleStyle(.checkbox)
                }
                PreferenceRow(t("玻璃透明度", "Glass Transparency")) {
                    HStack(spacing: 12) {
                        Slider(value: $preferences.values.glassTransparency, in: 0.15...0.85)
                            .frame(width: 220)
                            .disabled(!preferences.values.glassEffectEnabled)
                        Text("\(Int(preferences.values.glassTransparency * 100))%")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 42, alignment: .trailing)
                    }
                }
                PreferenceSupportingText(t(
                    "适用于设置与翻译窗口。系统支持时自动使用原生玻璃材质；文字与控件始终保持清晰。",
                    "Applies to Settings and translation windows. Native glass material is used when supported; text and controls remain opaque."
                ))
            }
            .controlSize(.regular)
            .frame(maxWidth: 700)
            .padding(.horizontal, 26)
            .padding(.vertical, 20)
        }
    }

    private func t(_ zh: String, _ en: String) -> String {
        PoptroText.value(zh, en, language: language)
    }
}

struct AboutView: View {
    @ObservedObject private var preferences = AppPreferencesStore.shared
    private var language: InterfaceLanguage { preferences.values.interfaceLanguage }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 22)
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 44, height: 44)
            Text("Poptro")
                .font(.headline)
                .padding(.top, 7)
            Text(t("版本", "Version") + " " + version)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            Form {
                Section {
                    LabeledContent(t("开发者", "Developer"), value: "Wayne")
                    LabeledContent(t("开源协议", "License"), value: "MIT License")
                    LabeledContent(t("系统要求", "System Requirements"), value: t("macOS 13 或更高版本", "macOS 13 or later"))
                }
                Section {
                    Toggle(t("自动检查更新", "Automatically Check for Updates"), isOn: $preferences.values.automaticUpdateChecks)
                        .toggleStyle(.checkbox)
                    LabeledContent(t("更新来源", "Update Source"), value: "GitHub Releases")
                    LabeledContent(t("软件更新", "Software Update")) {
                        Button(t("检查更新…", "Check for Updates…")) { AutoUpdater.checkForUpdates() }
                    }
                }
                Section {
                    LabeledContent(t("开源项目", "Open Source")) {
                        Link("github.com/mohist-club/Poptro", destination: URL(string: "https://github.com/mohist-club/Poptro/releases")!)
                    }
                    LabeledContent(t("网站社区", "Community")) {
                        Link("moaclab.com/t/topic/2638", destination: URL(string: "https://moaclab.com/t/topic/2638")!)
                    }
                }
            }
            .formStyle(.columns)
            .controlSize(.regular)
            .frame(width: 520)
            .padding(.top, 14)

            Label(
                t("API Key 与个人配置仅保存在当前 Mac，并在本地加密。", "API keys and personal settings stay encrypted on this Mac."),
                systemImage: "lock.fill"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 12)
            Text("© 2026 Wayne. Poptro is open source software.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 5)
            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0" }
    private func t(_ zh: String, _ en: String) -> String { PoptroText.value(zh, en, language: language) }
}
