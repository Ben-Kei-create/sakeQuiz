import Foundation

enum Level: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var localizedName: String {
        switch self {
        case .easy: return "初級"
        case .medium: return "中級"
        case .hard: return "上級"
        }
    }
}

struct QuizQuestion: Codable, Equatable, Identifiable {
    /// 固定ID（q001〜）。問題文を直しても、記録が引き継がれる。
    let id: String
    let question: String
    let choices: [String]
    let correctAnswerIndex: Int
    let trivia: String
    let difficulty: Level
    let category: QuizCategory
    let sourceTitle: String
    let sourceURL: String
    let checkedOn: String

    var correctChoice: String { choices[correctAnswerIndex] }
}
