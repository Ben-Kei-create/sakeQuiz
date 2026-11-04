import Foundation
import Observation

@Observable
final class GameStore {
    private enum Key {
        static let highScore = "nihonshuquiz.highScore"
        static let totalCorrect = "nihonshuquiz.totalCorrect"
        static let totalAnswered = "nihonshuquiz.totalAnswered"
        static let gamesPlayed = "nihonshuquiz.gamesPlayed"
        static let wrongQuestionIDs = "nihonshuquiz.wrongQuestionIDs"
        static let lastDailyDate = "nihonshuquiz.lastDailyDate"
        static let questionStats = "nihonshuquiz.questionStats"
        static let categoryStats = "nihonshuquiz.categoryStats"
        static let currentStreak = "nihonshuquiz.currentStreak"
        static let bestStreak = "nihonshuquiz.bestStreak"
    }

    @ObservationIgnored private let defaults: UserDefaults

    private(set) var highScore: Int
    private(set) var totalCorrect: Int
    private(set) var totalAnswered: Int
    private(set) var gamesPlayed: Int
    private(set) var wrongQuestionIDs: [String]
    private(set) var lastDailyDate: String?
    private(set) var questionStats: [String: QuestionStat]
    private(set) var categoryStats: [String: CategoryStat]
    private(set) var currentStreak: Int
    private(set) var bestStreak: Int

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        highScore = defaults.integer(forKey: Key.highScore)
        totalCorrect = defaults.integer(forKey: Key.totalCorrect)
        totalAnswered = defaults.integer(forKey: Key.totalAnswered)
        gamesPlayed = defaults.integer(forKey: Key.gamesPlayed)
        wrongQuestionIDs = defaults.stringArray(forKey: Key.wrongQuestionIDs) ?? []
        lastDailyDate = defaults.string(forKey: Key.lastDailyDate)
        questionStats = Self.decode(defaults, Key.questionStats) ?? [:]
        categoryStats = Self.decode(defaults, Key.categoryStats) ?? [:]
        currentStreak = defaults.integer(forKey: Key.currentStreak)
        bestStreak = defaults.integer(forKey: Key.bestStreak)
    }

    private static func decode<T: Decodable>(_ defaults: UserDefaults, _ key: String) -> T? {
        defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }

    func categoryAccuracy(_ category: QuizCategory) -> CategoryStat {
        categoryStats[category.rawValue] ?? CategoryStat()
    }

    var accuracyPercent: Int? {
        guard totalAnswered > 0 else {
            return nil
        }

        return Int((Double(totalCorrect) / Double(totalAnswered) * 100).rounded())
    }

    // MARK: - Answers and games

    func recordAnswer(_ record: AnswerRecord) {
        let id = record.question.id
        totalAnswered += 1

        if record.isCorrect {
            totalCorrect += 1
            wrongQuestionIDs.removeAll { $0 == id }
        } else if !wrongQuestionIDs.contains(id) {
            wrongQuestionIDs.append(id)
        }

        var stat = questionStats[id] ?? QuestionStat()
        var category = categoryStats[record.question.category.rawValue] ?? CategoryStat()
        category.answered += 1

        if record.isCorrect {
            stat.correctCount += 1
            stat.streak += 1
            category.correct += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
        } else {
            stat.wrongCount += 1
            stat.streak = 0
            currentStreak = 0
        }

        questionStats[id] = stat
        categoryStats[record.question.category.rawValue] = category

        defaults.set(totalAnswered, forKey: Key.totalAnswered)
        defaults.set(totalCorrect, forKey: Key.totalCorrect)
        defaults.set(wrongQuestionIDs, forKey: Key.wrongQuestionIDs)
        save(questionStats, forKey: Key.questionStats)
        save(categoryStats, forKey: Key.categoryStats)
        defaults.set(currentStreak, forKey: Key.currentStreak)
        defaults.set(bestStreak, forKey: Key.bestStreak)
    }

    /// 通常モードの1回分が終わったときに呼ぶ。ハイスコアを更新したら true。
    @discardableResult
    func recordGameFinished(score: Int) -> Bool {
        gamesPlayed += 1
        defaults.set(gamesPlayed, forKey: Key.gamesPlayed)

        guard score > highScore else {
            return false
        }

        highScore = score
        defaults.set(highScore, forKey: Key.highScore)
        return true
    }

    func resetStats() {
        highScore = 0
        totalCorrect = 0
        totalAnswered = 0
        gamesPlayed = 0
        wrongQuestionIDs = []
        lastDailyDate = nil
        questionStats = [:]
        categoryStats = [:]
        currentStreak = 0
        bestStreak = 0

        for key in [Key.highScore, Key.totalCorrect, Key.totalAnswered, Key.gamesPlayed, Key.wrongQuestionIDs, Key.lastDailyDate,
                    Key.questionStats, Key.categoryStats, Key.currentStreak, Key.bestStreak] {
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: - Review

    func reviewQuestions(from questions: [QuizQuestion]) -> [QuizQuestion] {
        questions.filter { wrongQuestionIDs.contains($0.id) }
            .sorted { (questionStats[$0.id]?.wrongCount ?? 0) > (questionStats[$1.id]?.wrongCount ?? 0) }
    }

    /// 弱点の分野（回答5問以上で正答率が最も低い分野）。
    func weakestCategory() -> QuizCategory? {
        QuizCategory.allCases
            .filter { categoryAccuracy($0).answered >= 5 }
            .min { (categoryAccuracy($0).accuracyPercent ?? 100) < (categoryAccuracy($1).accuracyPercent ?? 100) }
    }

    // MARK: - Daily

    func dailyQuestion(from questions: [QuizQuestion], on date: Date = .now) -> QuizQuestion? {
        guard !questions.isEmpty else {
            return nil
        }

        let calendar = Calendar.current
        let epoch = calendar.startOfDay(for: Date(timeIntervalSinceReferenceDate: 0))
        let dayNumber = calendar.dateComponents([.day], from: epoch, to: calendar.startOfDay(for: date)).day ?? 0
        let index = ((dayNumber % questions.count) + questions.count) % questions.count
        return questions[index]
    }

    func isDailyCompleted(on date: Date = .now) -> Bool {
        lastDailyDate == Self.dayKey(for: date)
    }

    func recordDailyCompleted(on date: Date = .now) {
        lastDailyDate = Self.dayKey(for: date)
        defaults.set(lastDailyDate, forKey: Key.lastDailyDate)
    }

    private static func dayKey(for date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
