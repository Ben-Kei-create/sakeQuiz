import XCTest

final class FlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(dayOffset: Int = 0, keepState: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-ui-day-offset", "\(dayOffset)"]
        if keepState { app.launchArguments.append("-ui-keep-state") }
        app.launch()
        return app
    }

    private func answerAll(_ app: XCUIApplication) {
        var guardCount = 0
        while !app.buttons["back_to_book_button"].exists && guardCount < 6 {
            let choice = app.buttons["choice_0"]
            XCTAssertTrue(choice.waitForExistence(timeout: 5))
            choice.tap()
            let next = app.buttons["next_button"]
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            next.tap()
            guardCount += 1
        }
    }

    func testFirstDayThenClosedUntilTomorrow() {
        let app = launch()
        XCTAssertTrue(app.buttons["start_lesson_button"].waitForExistence(timeout: 15))
        app.buttons["start_lesson_button"].tap()
        XCTAssertTrue(app.buttons["finish_reading_button"].waitForExistence(timeout: 5))
        app.buttons["finish_reading_button"].tap()
        answerAll(app)
        XCTAssertTrue(app.buttons["back_to_book_button"].waitForExistence(timeout: 5))
        app.buttons["back_to_book_button"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["closed_notice"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["start_lesson_button"].exists)
    }

    func testWrongAnswerAppearsInReviewTomorrow() {
        var app = launch()
        XCTAssertTrue(app.buttons["start_lesson_button"].waitForExistence(timeout: 15))
        app.buttons["start_lesson_button"].tap()
        app.buttons["finish_reading_button"].tap()
        // 正解は先頭ではない問いもあるので、全部「四」を選び、少なくとも1問は間違える
        var count = 0
        while !app.buttons["back_to_book_button"].exists && count < 6 {
            let choice = app.buttons["choice_3"]
            XCTAssertTrue(choice.waitForExistence(timeout: 5))
            choice.tap()
            app.buttons["next_button"].tap()
            count += 1
        }
        app.terminate()
        app = launch(dayOffset: 1, keepState: true)
        app.tabBars.buttons["復習"].tap()
        XCTAssertTrue(app.buttons["start_review_button"].waitForExistence(timeout: 5))
    }

    func testSettingsShowsVersion() {
        let app = launch()
        XCTAssertTrue(app.buttons["settings_button"].waitForExistence(timeout: 15))
        app.buttons["settings_button"].tap()
        let version = app.descendants(matching: .any)["app_version"].firstMatch
        XCTAssertTrue(version.waitForExistence(timeout: 5))
        XCTAssertEqual(version.value as? String, "1.0.0")
    }
}
