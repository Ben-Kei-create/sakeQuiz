import XCTest
@testable import NihonshuQuiz

final class ProgressStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        suite = "ProgressStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private func date(_ key: String, hour: Int = 9) -> Date {
        DayKey.date(from: key, calendar: calendar)!.addingTimeInterval(TimeInterval(hour * 3600))
    }

    private func makeStore(totalDays: Int = 5) -> ProgressStore {
        ProgressStore(totalDays: totalDays, defaults: defaults, calendar: calendar)
    }

    func testDayKeyArithmeticAcrossMonthYearAndLeapDay() {
        XCTAssertEqual(DayKey.adding(days: 1, to: "2026-12-31", calendar: calendar), "2027-01-01")
        XCTAssertEqual(DayKey.adding(days: 1, to: "2028-02-28", calendar: calendar), "2028-02-29")
        XCTAssertEqual(DayKey.adding(days: -1, to: "2026-03-01", calendar: calendar), "2026-02-28")
        XCTAssertLessThan("2026-02-09", "2026-10-01")
    }

    func testOneLessonPerDayInOrder() {
        let store = makeStore()
        XCTAssertEqual(store.nextLessonDay, 1)
        XCTAssertTrue(store.isTodayOpen(on: date("2026-11-04")))
        XCTAssertFalse(store.completeLesson(day: 2, on: date("2026-11-04")), "順番を飛ばせない")
        XCTAssertTrue(store.completeLesson(day: 1, on: date("2026-11-04")))
        XCTAssertFalse(store.isTodayOpen(on: date("2026-11-04", hour: 23)), "同じ日は閉じる")
        XCTAssertFalse(store.completeLesson(day: 2, on: date("2026-11-04", hour: 23)))
        XCTAssertTrue(store.isTodayOpen(on: date("2026-11-05", hour: 0)))
        XCTAssertEqual(store.nextLessonDay, 2)
    }

    func testRewindingTheClockDoesNotOpenExtraLessons() {
        let store = makeStore()
        store.completeLesson(day: 1, on: date("2026-11-10"))
        XCTAssertFalse(store.isTodayOpen(on: date("2026-11-05")), "日付を戻しても開かない")
        XCTAssertFalse(store.completeLesson(day: 2, on: date("2026-11-05")))
        XCTAssertEqual(store.streak(on: date("2026-11-10")), 1)
    }

    func testStreakCountsConsecutiveDaysAndBreaks() {
        let store = makeStore(totalDays: 10)
        store.completeLesson(day: 1, on: date("2026-11-01"))
        store.completeLesson(day: 2, on: date("2026-11-02"))
        store.completeLesson(day: 3, on: date("2026-11-03"))
        XCTAssertEqual(store.streak(on: date("2026-11-03")), 3)
        XCTAssertEqual(store.streak(on: date("2026-11-04")), 3, "今日まだ仕込んでいなくても、昨日までは続いている")
        XCTAssertEqual(store.streak(on: date("2026-11-06")), 0, "1日空くと途切れる")
        store.completeLesson(day: 4, on: date("2026-11-06"))
        XCTAssertEqual(store.streak(on: date("2026-11-06")), 1)
    }

    func testFinishedCalendarIsNeverOpen() {
        let store = makeStore(totalDays: 1)
        store.completeLesson(day: 1, on: date("2026-11-01"))
        XCTAssertNil(store.nextLessonDay)
        XCTAssertFalse(store.isTodayOpen(on: date("2026-11-20")))
    }

    func testWrongAnswerSchedulesReviewAndSpacingGrowsThenGraduates() {
        let store = makeStore()
        store.recordLessonAnswer(questionID: "q1", isCorrect: false, on: date("2026-11-01"))
        XCTAssertEqual(store.state.reviews["q1"], ReviewEntry(stage: 0, dueOn: "2026-11-02"))
        XCTAssertTrue(store.dueReviewIDs(on: date("2026-11-01")).isEmpty)
        XCTAssertEqual(store.dueReviewIDs(on: date("2026-11-02")), ["q1"])

        store.recordReviewAnswer(questionID: "q1", isCorrect: true, on: date("2026-11-02"))
        XCTAssertEqual(store.state.reviews["q1"], ReviewEntry(stage: 1, dueOn: "2026-11-05"))
        store.recordReviewAnswer(questionID: "q1", isCorrect: true, on: date("2026-11-05"))
        XCTAssertEqual(store.state.reviews["q1"], ReviewEntry(stage: 2, dueOn: "2026-11-12"))
        store.recordReviewAnswer(questionID: "q1", isCorrect: true, on: date("2026-11-12"))
        XCTAssertNil(store.state.reviews["q1"], "3回正解で卒業")
        XCTAssertEqual(store.state.wrongCounts["q1"], 1)
    }

    func testWrongReviewResetsTheSpacing() {
        let store = makeStore()
        store.recordLessonAnswer(questionID: "q1", isCorrect: false, on: date("2026-11-01"))
        store.recordReviewAnswer(questionID: "q1", isCorrect: true, on: date("2026-11-02"))
        store.recordReviewAnswer(questionID: "q1", isCorrect: false, on: date("2026-11-05"))
        XCTAssertEqual(store.state.reviews["q1"], ReviewEntry(stage: 0, dueOn: "2026-11-06"))
        XCTAssertEqual(store.state.wrongCounts["q1"], 2)
    }

    func testCorrectLessonAnswerDoesNotScheduleReview() {
        let store = makeStore()
        store.recordLessonAnswer(questionID: "q1", isCorrect: true, on: date("2026-11-01"))
        XCTAssertTrue(store.state.reviews.isEmpty)
        XCTAssertEqual(store.state.answered, 1)
        XCTAssertEqual(store.state.correct, 1)
    }

    func testDueReviewsAreOrderedByWrongCount() {
        let store = makeStore()
        store.recordLessonAnswer(questionID: "a", isCorrect: false, on: date("2026-11-01"))
        store.recordLessonAnswer(questionID: "b", isCorrect: false, on: date("2026-11-01"))
        store.recordLessonAnswer(questionID: "b", isCorrect: false, on: date("2026-11-01"))
        XCTAssertEqual(store.dueReviewIDs(on: date("2026-11-02")), ["b", "a"])
    }

    func testSealIsAwardedOnlyOnce() {
        let store = makeStore()
        XCTAssertTrue(store.awardSeal("nada", on: date("2026-11-01")))
        XCTAssertFalse(store.awardSeal("nada", on: date("2026-11-09")))
        XCTAssertEqual(store.state.seals["nada"], "2026-11-01")
    }

    func testStatePersistsAndResetClearsEverything() {
        let first = makeStore()
        first.completeLesson(day: 1, on: date("2026-11-01"))
        first.recordLessonAnswer(questionID: "q1", isCorrect: false, on: date("2026-11-01"))
        first.awardSeal("nada", on: date("2026-11-01"))
        let second = makeStore()
        XCTAssertEqual(second.state, first.state)
        second.reset()
        XCTAssertEqual(makeStore().state, ProgressState())
    }

    func testCorruptDataRecoversFromBackupInsteadOfSilentlyWipingEverything() {
        let first = makeStore()
        first.completeLesson(day: 1, on: date("2026-11-01"))
        first.recordLessonAnswer(questionID: "q1", isCorrect: true, on: date("2026-11-01"))
        defaults.set(Data("not json".utf8), forKey: ProgressStore.stateKey)
        let recovered = makeStore()
        XCTAssertTrue(recovered.recoveredFromCorruption)
        XCTAssertEqual(recovered.completedCount, 1)
        XCTAssertNotNil(defaults.data(forKey: "kome.state.v1.corrupt"))
    }

    func testCorruptDataWithoutBackupStartsEmptyAndSaysSo() {
        defaults.set(Data("{".utf8), forKey: ProgressStore.stateKey)
        let store = makeStore()
        XCTAssertTrue(store.recoveredFromCorruption)
        XCTAssertEqual(store.state, ProgressState())
    }
}
