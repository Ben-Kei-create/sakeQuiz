import XCTest
@testable import NihonshuQuiz

final class QuestionRepositoryTests: XCTestCase {
    func testBundledQuestionDataDecodesAndValidates() throws {
        let questions = try QuestionRepository.decodeQuestions(from: bundledQuestionData())

        XCTAssertGreaterThanOrEqual(questions.count, 150)
        XCTAssertTrue(questions.allSatisfy { $0.choices.count == 4 })
        XCTAssertTrue(questions.allSatisfy { $0.choices.indices.contains($0.correctAnswerIndex) })
    }

    func testSessionScoresCorrectAnswers() throws {
        let questions = try QuestionRepository.decodeQuestions(from: bundledQuestionData())
        var session = QuizSession(questions: Array(questions.prefix(2)), questionLimit: 2, shuffle: false)

        let firstAnswer = session.answerCurrentQuestion(selectedIndex: questions[0].correctAnswerIndex)
        session.moveToNextQuestion()
        let secondAnswer = session.answerCurrentQuestion(selectedIndex: nil)
        session.moveToNextQuestion()

        XCTAssertEqual(firstAnswer?.isCorrect, true)
        XCTAssertEqual(secondAnswer?.isCorrect, false)
        XCTAssertEqual(session.score, 1)
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.answerHistory.count, 2)
    }

    func testValidationRejectsInvalidCorrectAnswerIndex() throws {
        let invalidJSON = """
        [
          {
            "question": "Invalid?",
            "choices": ["A", "B", "C", "D"],
            "correctAnswerIndex": 4,
            "trivia": "Invalid index.",
            "difficulty": "Easy",
            "category": "rice"
          }
        ]
        """.data(using: .utf8)!

        XCTAssertThrowsError(try QuestionRepository.decodeQuestions(from: invalidJSON))
    }

    func testQuestionBankHasAllDifficultiesSourcesAndUniqueIDs() throws {
        let questions = try QuestionRepository.loadQuestions(from: Bundle.main)
        for difficulty in Difficulty.allCases {
            XCTAssertGreaterThan(questions.filter { $0.difficulty == difficulty }.count, 0)
        }
        XCTAssertEqual(Set(questions.map(\.id)).count, questions.count)
        for question in questions {
            XCTAssertNotNil(question.checkedOn)
            XCTAssertFalse(question.sourceTitle?.isEmpty ?? true)
            let url = try XCTUnwrap(URL(string: question.sourceURL ?? ""))
            XCTAssertEqual(url.scheme, "https")
            XCTAssertNotNil(url.host)
        }
    }

    func testSessionRejectsDuplicateAnswersAndCannotSkipUnansweredQuestion() throws {
        let questions = try QuestionRepository.decodeQuestions(from: bundledQuestionData())
        var session = QuizSession(questions: questions, shuffle: false)
        session.moveToNextQuestion()
        XCTAssertEqual(session.currentIndex, 0)
        XCTAssertNotNil(session.answerCurrentQuestion(selectedIndex: questions[0].correctAnswerIndex))
        XCTAssertNil(session.answerCurrentQuestion(selectedIndex: nil))
        XCTAssertEqual(session.score, 1)
        XCTAssertEqual(session.answerHistory.count, 1)
        session.moveToNextQuestion()
        XCTAssertEqual(session.currentIndex, 1)
    }

    func testNormalSessionContainsTenDistinctQuestions() throws {
        let questions = try QuestionRepository.decodeQuestions(from: bundledQuestionData())
        let session = QuizSession(questions: questions)
        XCTAssertEqual(session.questions.count, 10)
        XCTAssertEqual(Set(session.questions.map(\.id)).count, 10)
        XCTAssertEqual(Difficulty.easy.timeLimit, 25)
        XCTAssertEqual(Difficulty.medium.timeLimit, 20)
        XCTAssertEqual(Difficulty.hard.timeLimit, 18)
    }

    func testEmptyBankDuplicateQuestionsAndDuplicateChoicesAreRejected() throws {
        let question = try QuestionRepository.decodeQuestions(from: bundledQuestionData())[0]
        XCTAssertThrowsError(try QuestionRepository.validate([]))
        XCTAssertThrowsError(try QuestionRepository.validate([question, question]))
        let invalid = QuizQuestion(question: "duplicate choices", choices: ["A", "A", "C", "D"],
                                   correctAnswerIndex: 0, trivia: "explanation", difficulty: .easy, category: .rice)
        XCTAssertThrowsError(try QuestionRepository.validate([invalid]))
    }

    private func bundledQuestionData() throws -> Data {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let projectRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let jsonURL = projectRoot.appending(path: "NihonshuQuiz/Resources/nihonshu_quiz.json")
        return try Data(contentsOf: jsonURL)
    }
}
