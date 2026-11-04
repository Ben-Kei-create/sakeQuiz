import Foundation

/// 問題ごとの記録。間違えた回数と、現在の連続正解数。
struct QuestionStat: Codable, Equatable {
    var wrongCount = 0
    var correctCount = 0
    var streak = 0
}

/// 分野ごとの記録。
struct CategoryStat: Codable, Equatable {
    var answered = 0
    var correct = 0

    var accuracyPercent: Int? {
        guard answered > 0 else { return nil }
        return Int((Double(correct) / Double(answered) * 100).rounded())
    }
}
