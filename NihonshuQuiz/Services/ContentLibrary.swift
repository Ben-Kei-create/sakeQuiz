import Foundation

enum ContentError: Error, Equatable, LocalizedError {
    case missingResource(String)
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case let .missingResource(name): return "\(name) が見つかりません。"
        case let .invalid(reason): return "内容に不備があります：\(reason)"
        }
    }
}

/// 仕込み暦（読み物）と問題の束。
struct ContentLibrary {
    let lessons: [Lesson]
    let questions: [String: QuizQuestion]
    let seals: [SealDefinition]

    init(lessons: [Lesson], questions: [QuizQuestion], seals: [SealDefinition] = []) throws {
        try Self.validate(lessons: lessons, questions: questions)
        let known = Set(questions.map(\.id))
        guard seals.allSatisfy({ known.contains($0.questionID) }), Set(seals.map(\.id)).count == seals.count else {
            throw ContentError.invalid("印")
        }
        self.seals = seals
        self.lessons = lessons.sorted { $0.day < $1.day }
        self.questions = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0) })
    }

    static func load(from bundle: Bundle = .main) throws -> ContentLibrary {
        let questions: [QuizQuestion] = try decode("nihonshu_quiz", in: bundle)
        let lessons: [Lesson] = try decode("lessons", in: bundle)
        let seals: [SealDefinition] = try decode("seals", in: bundle)
        return try ContentLibrary(lessons: lessons, questions: questions, seals: seals)
    }

    private static func decode<T: Decodable>(_ name: String, in bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw ContentError.missingResource("\(name).json")
        }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }

    func lesson(day: Int) -> Lesson? { lessons.first { $0.day == day } }

    func seal(forQuestion id: String) -> SealDefinition? { seals.first { $0.questionID == id } }

    func questions(for lesson: Lesson) -> [QuizQuestion] { lesson.questionIDs.compactMap { questions[$0] } }

    static func validate(lessons: [Lesson], questions: [QuizQuestion]) throws {
        guard !questions.isEmpty else { throw ContentError.invalid("問題が空です") }
        guard Set(questions.map(\.id)).count == questions.count else { throw ContentError.invalid("問題IDが重複しています") }
        guard Set(questions.map(\.question)).count == questions.count else { throw ContentError.invalid("問題文が重複しています") }
        for q in questions {
            guard q.choices.count == 4, Set(q.choices).count == 4,
                  q.choices.indices.contains(q.correctAnswerIndex),
                  q.choices.allSatisfy({ !$0.trimmingCharacters(in: .whitespaces).isEmpty }),
                  !q.question.trimmingCharacters(in: .whitespaces).isEmpty,
                  !q.trivia.trimmingCharacters(in: .whitespaces).isEmpty,
                  q.sourceURL.hasPrefix("https://"), !q.checkedOn.isEmpty
            else { throw ContentError.invalid("問題 \(q.id)") }
        }
        guard !lessons.isEmpty else { throw ContentError.invalid("仕込み暦が空です") }
        let days = lessons.map(\.day).sorted()
        guard days == Array(1...lessons.count) else { throw ContentError.invalid("日の番号が1から連続していません") }
        let known = Set(questions.map(\.id))
        for l in lessons {
            guard !l.title.isEmpty, !l.body.isEmpty, !l.questionIDs.isEmpty,
                  l.sourceURL.hasPrefix("https://"), !l.checkedOn.isEmpty,
                  l.questionIDs.allSatisfy(known.contains)
            else { throw ContentError.invalid("\(l.day)日目") }
        }
    }
}
