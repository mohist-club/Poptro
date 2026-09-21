import AppKit
import Foundation

struct ShortcutExecutionSpec: Equatable {
    let executableURL: URL
    let arguments: [String]
}

final class AppLauncher: ObservableObject {
    static let shared = AppLauncher()
    @Published var bindings: [LaunchBinding]
    private let filename = "launch_bindings.json"

    private init() {
        bindings = LocalStore.load([LaunchBinding].self, filename: filename, default: [])
    }

    func scanInstalledApplications() -> [(name: String, path: String)] {
        let fm = FileManager.default
        var results: [(String, String)] = []
        let directories = [
            "/Applications", "/System/Applications",
            (NSHomeDirectory() as NSString).appendingPathComponent("Applications")
        ]
        for directory in directories {
            guard let items = try? fm.contentsOfDirectory(atPath: directory) else { continue }
            for item in items where item.hasSuffix(".app") {
                results.append(((item as NSString).deletingPathExtension,
                                (directory as NSString).appendingPathComponent(item)))
            }
        }
        return results.sorted { $0.0.localizedCaseInsensitiveCompare($1.0) == .orderedAscending }
    }

    func icon(forAppPath path: String) -> NSImage { NSWorkspace.shared.icon(forFile: path) }
    func bindings(of kind: ShortcutActionKind) -> [LaunchBinding] { bindings.filter { $0.actionKind == kind } }

    func addBinding(appName: String, appBundlePath: String) {
        add(LaunchBinding(appName: appName, appBundlePath: appBundlePath))
    }

    func addShortcut(named name: String) {
        guard !bindings.contains(where: { $0.actionKind == .shortcut && $0.appBundlePath == name }) else { return }
        add(LaunchBinding(appName: name, appBundlePath: name, actionKind: .shortcut))
    }

    func addSystemAction(_ action: SystemShortcutAction, displayName: String) {
        guard !bindings.contains(where: { $0.actionKind == .system && $0.appBundlePath == action.rawValue }) else { return }
        add(LaunchBinding(appName: displayName, appBundlePath: action.rawValue, actionKind: .system))
    }

    func addScript(name: String, source: String, kind: ShortcutScriptKind) {
        add(LaunchBinding(appName: name, appBundlePath: source, actionKind: .script, scriptKind: kind))
    }

    private func add(_ binding: LaunchBinding) {
        bindings.append(binding)
        persist()
        registerHotkey(for: binding)
    }

    func removeBinding(_ binding: LaunchBinding) {
        HotkeyManager.shared.unregisterDynamicHotkey(name: binding.hotkeyName)
        bindings.removeAll { $0.id == binding.id }
        persist()
    }

    func setEnabled(_ enabled: Bool, for binding: LaunchBinding) {
        guard let index = bindings.firstIndex(where: { $0.id == binding.id }) else { return }
        bindings[index].isEnabled = enabled
        if enabled { registerHotkey(for: bindings[index]) }
        else { HotkeyManager.shared.unregisterDynamicHotkey(name: binding.hotkeyName) }
        persist()
    }

    private func persist() { LocalStore.save(bindings, filename: filename) }

    func registerAllLaunchHotkeys() {
        for binding in bindings where binding.isEnabled { registerHotkey(for: binding) }
    }

    private func registerHotkey(for binding: LaunchBinding) {
        HotkeyManager.shared.registerDynamicHotkey(name: binding.hotkeyName) { [weak self] in self?.execute(binding) }
    }

    func listShortcuts(completion: @escaping (Result<[String], Error>) -> Void) {
        run(ShortcutExecutionSpec(
            executableURL: URL(fileURLWithPath: "/usr/bin/shortcuts"), arguments: ["list"]
        )) { result in
            completion(result.map { $0.split(whereSeparator: \.isNewline).map(String.init).filter { !$0.isEmpty } })
        }
    }

    func executionSpec(for binding: LaunchBinding) -> ShortcutExecutionSpec? {
        switch binding.actionKind {
        case .application, .system: return nil
        case .shortcut:
            return ShortcutExecutionSpec(executableURL: URL(fileURLWithPath: "/usr/bin/shortcuts"), arguments: ["run", binding.appBundlePath])
        case .script:
            switch binding.scriptKind ?? .shell {
            case .shell:
                return ShortcutExecutionSpec(executableURL: URL(fileURLWithPath: "/bin/zsh"), arguments: ["-lc", binding.appBundlePath])
            case .appleScript:
                return ShortcutExecutionSpec(executableURL: URL(fileURLWithPath: "/usr/bin/osascript"), arguments: ["-e", binding.appBundlePath])
            case .javaScript:
                return ShortcutExecutionSpec(executableURL: URL(fileURLWithPath: "/usr/bin/osascript"), arguments: ["-l", "JavaScript", "-e", binding.appBundlePath])
            }
        }
    }

    private func execute(_ binding: LaunchBinding) {
        switch binding.actionKind {
        case .application:
            NSWorkspace.shared.openApplication(
                at: URL(fileURLWithPath: binding.appBundlePath),
                configuration: NSWorkspace.OpenConfiguration()
            ) { [weak self] _, error in if let error { self?.present(error) } }
        case .system:
            guard let action = SystemShortcutAction(rawValue: binding.appBundlePath) else { return }
            executeSystemAction(action, displayName: binding.appName)
        case .shortcut, .script:
            guard let spec = executionSpec(for: binding) else { return }
            run(spec) { [weak self] result in if case .failure(let error) = result { self?.present(error) } }
        }
    }

    private func executeSystemAction(_ action: SystemShortcutAction, displayName: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if action.requiresConfirmation {
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = displayName
                let language = AppPreferencesStore.shared.values.interfaceLanguage
                alert.informativeText = PoptroText.value(
                    "此系统操作会立即生效，是否继续？",
                    "This system action takes effect immediately. Continue?",
                    language: language
                )
                alert.addButton(withTitle: PoptroText.value("继续", "Continue", language: language))
                alert.addButton(withTitle: PoptroText.value("取消", "Cancel", language: language))
                guard alert.runModal() == .alertFirstButtonReturn else { return }
            }
            let source: String
            switch action {
            case .lockScreen: source = "tell application \"System Events\" to keystroke \"q\" using {control down, command down}"
            case .sleep: source = "tell application \"System Events\" to sleep"
            case .emptyTrash: source = "tell application \"Finder\" to empty trash"
            case .logOut: source = "tell application \"System Events\" to log out"
            case .restart: source = "tell application \"System Events\" to restart"
            case .shutDown: source = "tell application \"System Events\" to shut down"
            }
            var errorInfo: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&errorInfo)
            if let errorInfo {
                self.present(NSError(
                    domain: "Poptro.SystemAction",
                    code: errorInfo[NSAppleScript.errorNumber] as? Int ?? 1,
                    userInfo: [NSLocalizedDescriptionKey: errorInfo[NSAppleScript.errorMessage] as? String ?? "系统操作失败"]
                ))
            }
        }
    }

    private func run(_ spec: ShortcutExecutionSpec, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            let pipe = Pipe()
            process.executableURL = spec.executableURL
            process.arguments = spec.arguments
            process.standardOutput = pipe
            process.standardError = pipe
            do {
                try process.run()
                process.waitUntilExit()
                let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                guard process.terminationStatus == 0 else {
                    throw NSError(domain: "Poptro.ShortcutAction", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output.isEmpty ? "操作执行失败" : output])
                }
                DispatchQueue.main.async { completion(.success(output)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    private func present(_ error: Error) {
        DispatchQueue.main.async { NSAlert(error: error).runModal() }
    }
}
