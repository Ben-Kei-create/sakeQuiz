import Foundation

/// 復習の予約。stage は、これまでに正解した復習の回数。
struct ReviewEntry: Codable, Equatable {
    var stage: Int
    var dueOn: String
}

/// 端末内に保存する記録のすべて。
struct ProgressState: Codable, Equatable {
    /// 仕込み日（通し番号）→ 完了した日。
    var completions: [Int: String] = [:]
    var reviews: [String: ReviewEntry] = [:]
    var wrongCounts: [String: Int] = [:]
    /// 印の名前 → 押した日。
    var seals: [String: String] = [:]
    var answered = 0
    var correct = 0
}

/// 復習の間隔。間違えた翌日、その後3日、さらに7日。
enum ReviewSchedule {
    static let intervals = [1, 3, 7]
}
