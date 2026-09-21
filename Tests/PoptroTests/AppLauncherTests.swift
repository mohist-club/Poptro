import XCTest
@testable import Poptro

final class AppLauncherTests: XCTestCase {
    func testLegacyApplicationBindingDecodesAsApplication() throws {
        let id = UUID()
        let data = """
        {"id":"\(id.uuidString)","appName":"Safari","appBundlePath":"/Applications/Safari.app","isEnabled":true}
        """.data(using: .utf8)!
        let binding = try JSONDecoder().decode(LaunchBinding.self, from: data)
        XCTAssertEqual(binding.actionKind, .application)
        XCTAssertNil(binding.scriptKind)
        XCTAssertTrue(binding.hotkeyName.contains(id.uuidString))
    }

    func testShortcutExecutionKeepsNameAsSingleArgument() {
        let binding = LaunchBinding(appName: "Translate Text", appBundlePath: "Translate Text", actionKind: .shortcut)
        let spec = AppLauncher.shared.executionSpec(for: binding)
        XCTAssertEqual(spec?.executableURL.path, "/usr/bin/shortcuts")
        XCTAssertEqual(spec?.arguments, ["run", "Translate Text"])
    }

    func testScriptExecutionDoesNotInterpolateSourceIntoExecutablePath() {
        let source = "printf '%s' '$HOME'"
        let binding = LaunchBinding(appName: "Test", appBundlePath: source, actionKind: .script, scriptKind: .shell)
        let spec = AppLauncher.shared.executionSpec(for: binding)
        XCTAssertEqual(spec?.executableURL.path, "/bin/zsh")
        XCTAssertEqual(spec?.arguments, ["-lc", source])
    }

    func testDestructiveSystemActionsRequireConfirmation() {
        XCTAssertFalse(SystemShortcutAction.lockScreen.requiresConfirmation)
        XCTAssertFalse(SystemShortcutAction.sleep.requiresConfirmation)
        XCTAssertTrue(SystemShortcutAction.emptyTrash.requiresConfirmation)
        XCTAssertTrue(SystemShortcutAction.restart.requiresConfirmation)
        XCTAssertTrue(SystemShortcutAction.shutDown.requiresConfirmation)
    }
}
