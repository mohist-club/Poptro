import Translation
import XCTest
@testable import Poptro

final class AppleTranslationTests: XCTestCase {
    func testSystemAvailabilityFlagMatchesDeploymentAvailability() {
        if #available(macOS 15.0, *) {
            XCTAssertTrue(AppleTranslationSupport.isAvailable)
        } else {
            XCTAssertFalse(AppleTranslationSupport.isAvailable)
        }
    }

    @available(macOS 15.0, *)
    func testAppleFrameworkReportsSupportedLanguages() async {
        let languages = await LanguageAvailability().supportedLanguages
        XCTAssertFalse(languages.isEmpty)
    }
}
