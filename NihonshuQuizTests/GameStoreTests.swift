import XCTest
@testable import NihonshuQuiz

final class GameStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "GameStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeQuestion(_ text: String, category: QuizCategory = .rice) -> QuizQuestion {
        QuizQuestion(
            question: text,
            choices: ["A", "B", "C", "D"],
            correctAnswerIndex: 0,
            trivia: "trivia",
            difficulty: .easy,
            category: category
        )
    }

    func testWrongAnswerIsStoredAndClearedWhenAnsweredCorrectly() {
        let store = GameStore(defaults: defaults)
        let question = makeQuestion("Q1")

        store.recordAnswer(AnswerRecord(question: question, selectedIndex: 1))
        XCTAssertEqual(store.wrongQuestionIDs, [question.id])
        XCTAssertEqual(store.reviewQuestions(from: [question]).count, 1)

        store.recordAnswer(AnswerRecord(question: question, selectedIndex: 0))
        XCTAssertTrue(store.wrongQuestionIDs.isEmpty)
        XCTAssertEqual(store.totalAnswered, 2)
        XCTAssertEqual(store.totalCorrect, 1)
        XCTAssertEqual(store.accuracyPercent, 50)
    }

    func testHighScoreOnlyUpdatesWhenBeaten() {
        let store = GameStore(defaults: defaults)

        XCTAssertTrue(store.recordGameFinished(score: 6))
        XCTAssertFalse(store.recordGameFinished(score: 6))
        XCTAssertFalse(store.recordGameFinished(score: 4))
        XCTAssertTrue(store.recordGameFinished(score: 9))
        XCTAssertEqual(store.highScore, 9)
        XCTAssertEqual(store.gamesPlayed, 4)
    }

    func testStatsPersistAcrossInstances() {
        let first = GameStore(defaults: defaults)
        first.recordGameFinished(score: 7)
        first.recordAnswer(AnswerRecord(question: makeQuestion("Q1"), selectedIndex: 2))

        let second = GameStore(defaults: defaults)
        XCTAssertEqual(second.highScore, 7)
        XCTAssertEqual(second.wrongQuestionIDs, ["Q1"])
    }

    func testDailyQuestionIsStableWithinADayAndCompletionResetsNextDay() {
        let store = GameStore(defaults: defaults)
        let questions = (0..<5).map { makeQuestion("Q\($0)") }
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        XCTAssertEqual(store.dailyQuestion(from: questions, on: today), store.dailyQuestion(from: questions, on: today))
        XCTAssertNotEqual(store.dailyQuestion(from: questions, on: today), store.dailyQuestion(from: questions, on: tomorrow))

        XCTAssertFalse(store.isDailyCompleted(on: today))
        store.recordDailyCompleted(on: today)
        XCTAssertTrue(store.isDailyCompleted(on: today))
        XCTAssertFalse(store.isDailyCompleted(on: tomorrow))
    }

    func testResetStatsClearsEverything() {
        let store = GameStore(defaults: defaults)
        store.recordGameFinished(score: 5)
        store.recordAnswer(AnswerRecord(question: makeQuestion("Q1"), selectedIndex: 3))
        store.recordDailyCompleted()

        store.resetStats()

        XCTAssertEqual(store.highScore, 0)
        XCTAssertEqual(store.totalAnswered, 0)
        XCTAssertTrue(store.wrongQuestionIDs.isEmpty)
        XCTAssertFalse(store.isDailyCompleted())
        XCTAssertNil(store.accuracyPercent)
    }

    func testNihonshuKeysAreIsolatedAndResetDoesNotDeleteOtherAppsData() {
        defaults.set(9, forKey: "highScore")
        defaults.set("keep", forKey: "other.preference")
        let store = GameStore(defaults: defaults)
        XCTAssertEqual(store.highScore, 0)
        store.recordGameFinished(score: 7)
        XCTAssertEqual(defaults.integer(forKey: "nihonshuquiz.highScore"), 7)
        XCTAssertEqual(defaults.integer(forKey: "highScore"), 9)
        store.resetStats()
        XCTAssertEqual(defaults.integer(forKey: "highScore"), 9)
        XCTAssertEqual(defaults.string(forKey: "other.preference"), "keep")
    }

    func testTimeoutIsReviewedWithoutDuplicatingTheReviewList() {
        let store = GameStore(defaults: defaults)
        let question = makeQuestion("timeout")
        store.recordAnswer(AnswerRecord(question: question, selectedIndex: nil))
        store.recordAnswer(AnswerRecord(question: question, selectedIndex: nil))
        XCTAssertEqual(store.wrongQuestionIDs, [question.id])
        XCTAssertEqual(store.totalCorrect, 0)
        XCTAssertEqual(GameStore(defaults: defaults).totalAnswered, 2)
    }

    func testDailyHandlesEmptyBankAndCompletionPersists() {
        let store = GameStore(defaults: defaults)
        XCTAssertNil(store.dailyQuestion(from: []))
        store.recordDailyCompleted()
        XCTAssertTrue(GameStore(defaults: defaults).isDailyCompleted())
    }

    @MainActor
    func testAdsAreBlockedBeforeConsentAndNoOptionsAreInitiallyShown() {
        let privacy = AdsPrivacyController()
        XCTAssertFalse(privacy.canRequestAds)
        XCTAssertFalse(privacy.isPrivacyOptionsRequired)
        XCTAssertEqual(privacy.adGeneration, 0)
    }

    func testWrongCountStreakAndCategoryStats() {
        let store = GameStore(defaults: defaults)
        let rice = makeQuestion("R1", category: .rice)
        let brewing = makeQuestion("B1", category: .brewing)

        store.recordAnswer(AnswerRecord(question: rice, selectedIndex: 1))
        store.recordAnswer(AnswerRecord(question: rice, selectedIndex: nil))
        XCTAssertEqual(store.questionStats[rice.id]?.wrongCount, 2)
        XCTAssertEqual(store.currentStreak, 0)

        store.recordAnswer(AnswerRecord(question: rice, selectedIndex: 0))
        store.recordAnswer(AnswerRecord(question: brewing, selectedIndex: 0))
        XCTAssertEqual(store.currentStreak, 2)
        XCTAssertEqual(store.bestStreak, 2)
        XCTAssertEqual(store.questionStats[rice.id]?.streak, 1)
        XCTAssertEqual(store.categoryAccuracy(.rice), CategoryStat(answered: 3, correct: 1))
        XCTAssertEqual(store.categoryAccuracy(.brewing).accuracyPercent, 100)

        store.recordAnswer(AnswerRecord(question: brewing, selectedIndex: 1))
        XCTAssertEqual(store.currentStreak, 0)
        XCTAssertEqual(store.bestStreak, 2)

        let reloaded = GameStore(defaults: defaults)
        XCTAssertEqual(reloaded.bestStreak, 2)
        XCTAssertEqual(reloaded.categoryAccuracy(.rice).answered, 3)
    }

    func testReviewIsOrderedByWrongCountAndResetClearsNewStats() {
        let store = GameStore(defaults: defaults)
        let a = makeQuestion("A"), b = makeQuestion("B")
        store.recordAnswer(AnswerRecord(question: a, selectedIndex: 1))
        store.recordAnswer(AnswerRecord(question: b, selectedIndex: 1))
        store.recordAnswer(AnswerRecord(question: b, selectedIndex: 1))
        XCTAssertEqual(store.reviewQuestions(from: [a, b]).map(\.id), ["B", "A"])

        store.resetStats()
        XCTAssertTrue(store.questionStats.isEmpty)
        XCTAssertEqual(store.categoryAccuracy(.rice).answered, 0)
        XCTAssertEqual(store.bestStreak, 0)
    }

    func testWeakestCategoryNeedsFiveAnswers() {
        let store = GameStore(defaults: defaults)
        let q = makeQuestion("W", category: .taste)
        for _ in 0..<4 { store.recordAnswer(AnswerRecord(question: q, selectedIndex: 1)) }
        XCTAssertNil(store.weakestCategory())
        store.recordAnswer(AnswerRecord(question: q, selectedIndex: 1))
        XCTAssertEqual(store.weakestCategory(), .taste)
    }
}
