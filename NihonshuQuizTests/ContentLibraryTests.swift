import XCTest
@testable import NihonshuQuiz

final class ContentLibraryTests: XCTestCase {
    private func question(_ id: String, text: String? = nil) -> QuizQuestion {
        QuizQuestion(id: id, question: text ?? "問題\(id)", choices: ["あ", "い", "う", "え"], correctAnswerIndex: 1,
                     trivia: "解説", difficulty: .easy, category: .rice,
                     sourceTitle: "出典", sourceURL: "https://example.com", checkedOn: "2026-11-04")
    }

    private func lesson(_ day: Int, ids: [String] = ["q1"]) -> Lesson {
        Lesson(day: day, title: "工程", body: "本文", questionIDs: ids, sourceTitle: "出典", sourceURL: "https://example.com", checkedOn: "2026-11-04")
    }

    func testValidContentLoads() throws {
        let library = try ContentLibrary(lessons: [lesson(2), lesson(1)], questions: [question("q1")])
        XCTAssertEqual(library.lessons.map(\.day), [1, 2])
        XCTAssertEqual(library.questions(for: library.lessons[0]).count, 1)
    }

    func testRejectsBrokenContent() {
        XCTAssertThrowsError(try ContentLibrary(lessons: [lesson(1)], questions: []))
        XCTAssertThrowsError(try ContentLibrary(lessons: [lesson(1)], questions: [question("q1"), question("q1", text: "別")]))
        XCTAssertThrowsError(try ContentLibrary(lessons: [lesson(1)], questions: [question("q1"), question("q2", text: "問題q1")]))
        XCTAssertThrowsError(try ContentLibrary(lessons: [lesson(1), lesson(3)], questions: [question("q1")]), "日の番号が飛んでいる")
        XCTAssertThrowsError(try ContentLibrary(lessons: [lesson(1, ids: ["missing"])], questions: [question("q1")]))
        XCTAssertThrowsError(try ContentLibrary(lessons: [lesson(1, ids: [])], questions: [question("q1")]))
    }

    func testBundledQuestionBankIsSoundAndEveryQuestionIsCited() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "NihonshuQuiz/Resources/nihonshu_quiz.json")
        let questions = try JSONDecoder().decode([QuizQuestion].self, from: Data(contentsOf: url))
        XCTAssertGreaterThanOrEqual(questions.count, 150)
        XCTAssertEqual(Set(questions.map(\.id)).count, questions.count)
        XCTAssertEqual(Set(questions.map(\.question)).count, questions.count)
        for q in questions {
            XCTAssertEqual(q.choices.count, 4)
            XCTAssertEqual(Set(q.choices).count, 4, q.id)
            XCTAssertTrue(q.choices.indices.contains(q.correctAnswerIndex), q.id)
            XCTAssertTrue(q.sourceURL.hasPrefix("https://"), q.id)
        }
    }

    func testBundledCalendarHasSixtyConsistentDaysAndEverySealIsReachable() throws {
        let library = try ContentLibrary.load(from: Bundle(for: ProgressStore.self))
        XCTAssertEqual(library.lessons.count, 60)
        let inLessons = Set(library.lessons.flatMap(\.questionIDs))
        XCTAssertEqual(inLessons.count, library.lessons.flatMap(\.questionIDs).count, "同じ問題が2日に出ている")
        for lesson in library.lessons {
            XCTAssertTrue((1...6).contains(lesson.questionIDs.count), "\(lesson.day)日目の問題数")
            XCTAssertGreaterThanOrEqual(lesson.body.count, 60, "\(lesson.day)日目の読み物が短い")
        }
        for seal in library.seals {
            XCTAssertTrue(inLessons.contains(seal.questionID), "\(seal.name) の印に届かない")
        }
    }
}

