import XCTest

final class NihonshuQuizUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["start_quiz_button"].waitForExistence(timeout: 15))
        return app
    }

    private func visibleTap(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<5 {
            if element.exists && element.isHittable { element.tap(); return }
            if element.exists && element.frame.midY < app.frame.midY {
                app.swipeDown()
            } else { app.swipeUp() }
        }
        XCTFail("Element is not reachable: \(element)")
    }

    private func answer(_ app: XCUIApplication) {
        let choice = app.buttons["choice_0"]
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        visibleTap(choice, app: app)
        let next = app.buttons["next_question_button"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        visibleTap(next, app: app)
    }

    func testNormalQuizResultShareAndReview() {
        let app = launch()
        app.buttons["start_quiz_button"].tap()
        for _ in 0..<10 { answer(app) }
        XCTAssertTrue(app.buttons["結果をシェア"].waitForExistence(timeout: 5))
        app.buttons["結果をシェア"].tap()
        XCTAssertTrue(app.navigationBars["UIActivityContentView"].waitForExistence(timeout: 5)
                      || app.buttons["Close"].exists || app.buttons["閉じる"].exists || app.otherElements["ActivityListView"].exists)
        // iOS 27 presents the share sheet as a popover; tapping outside dismisses it.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.1)).tap()
        let homeButton = app.buttons["ホームに戻る"]
        XCTAssertTrue(homeButton.waitForExistence(timeout: 5))
        // After a popover closes UIKit can temporarily report SwiftUI buttons as non-hittable.
        homeButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["start_quiz_button"].waitForExistence(timeout: 5))
        let review = app.buttons["review_quiz_button"]
        visibleTap(review, app: app)
        answer(app)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "review-answer"; shot.lifetime = .keepAlways; add(shot)
    }

    func testDailyCompletionAndSettings() {
        let app = launch()
        let home = XCTAttachment(screenshot: app.screenshot())
        home.name = "home"; home.lifetime = .keepAlways; add(home)
        visibleTap(app.buttons["daily_quiz_button"], app: app)
        answer(app)
        let afterDaily = XCTAttachment(screenshot: app.screenshot())
        afterDaily.name = "after-daily-answer"; afterDaily.lifetime = .keepAlways; add(afterDaily)
        XCTAssertTrue(app.buttons["ホームに戻る"].waitForExistence(timeout: 5))
        app.buttons["ホームに戻る"].tap()
        let daily = app.buttons["daily_quiz_button"]
        XCTAssertTrue(daily.waitForExistence(timeout: 5))
        XCTAssertFalse(daily.isEnabled)
        app.swipeDown()
        app.buttons["settings_button"].tap()
        let version = app.descendants(matching: .any)["app_version"].firstMatch
        XCTAssertTrue(version.waitForExistence(timeout: 5))
        XCTAssertEqual(version.value as? String, "1.0.0")
        app.buttons["プライバシーポリシー"].tap()
        XCTAssertTrue(app.staticTexts["日本酒雑学クイズ"].exists)
    }
}
