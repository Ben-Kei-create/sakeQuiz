import Foundation

struct QuizQuestion: Codable, Equatable, Identifiable {
    var id: String { question }

    let question: String
    let choices: [String]
    let correctAnswerIndex: Int
    let trivia: String
    let difficulty: Difficulty
    let category: QuizCategory

    var sourceTitle: String?
    var sourceURL: String?
    var checkedOn: String?

    var correctChoice: String {
        choices[correctAnswerIndex]
    }
}
