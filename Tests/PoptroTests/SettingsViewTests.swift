import AppKit
import SwiftUI
import XCTest
@testable import Poptro

@MainActor
final class SettingsViewTests: XCTestCase {
    func testSettingsWindowRendersAtSafariScale() throws {
        try renderSettings(
            destination: .general,
            captureEnvironmentKey: "POPTRO_SETTINGS_CAPTURE"
        )
    }

    func testServicesSettingsRendersAtSafariScale() throws {
        try renderSettings(
            destination: .services,
            captureEnvironmentKey: "POPTRO_SERVICES_CAPTURE"
        )
    }

    private func renderSettings(
        destination: SettingsDestination,
        captureEnvironmentKey: String
    ) throws {
        _ = NSApplication.shared
        let controller = NSHostingController(
            rootView: SettingsView(initialDestination: destination)
                .frame(width: 900, height: 620)
        )
        controller.view.frame = NSRect(x: 0, y: 0, width: 900, height: 620)
        RunLoop.main.run(until: Date().addingTimeInterval(0.15))
        controller.view.layoutSubtreeIfNeeded()

        XCTAssertEqual(controller.view.bounds.width, 900, accuracy: 0.5)
        XCTAssertEqual(controller.view.bounds.height, 620, accuracy: 0.5)

        if let capturePath = ProcessInfo.processInfo.environment[captureEnvironmentKey],
           let bitmap = controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds) {
            controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
            try bitmap.representation(using: .png, properties: [:])?
                .write(to: URL(fileURLWithPath: capturePath))
        }
    }
}
