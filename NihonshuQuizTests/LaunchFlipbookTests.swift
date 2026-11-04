import XCTest
@testable import NihonshuQuiz

final class LaunchFlipbookTests: XCTestCase {
    func testDoesNotShowDuringUITestsOrScreenshots() {
        XCTAssertFalse(LaunchFlipbook.shouldShow(arguments: ["-ui-testing"]))
        XCTAssertFalse(LaunchFlipbook.shouldShow(arguments: ["-SCREENSHOT_MODE"]))
    }

    func testFrameNamesAreConsecutiveFromOne() {
        let names = LaunchFlipbook.frameNames()
        for (i, name) in names.enumerated() { XCTAssertEqual(name, "splash_\(i + 1)") }
    }
}
