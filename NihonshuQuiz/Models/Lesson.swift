import Foundation

/// 仕込み暦の1日分。読み物と、その日の確認問題。
struct Lesson: Codable, Identifiable, Equatable {
    /// 1日目から始まる通し番号。
    let day: Int
    let title: String
    let body: String
    let questionIDs: [String]
    let sourceTitle: String
    let sourceURL: String
    let checkedOn: String

    var id: Int { day }
}
