import Foundation

/// 蔵印帳の1つの印。対応する問題に正解すると押される。
struct SealDefinition: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let place: String
    let note: String
    let questionID: String
}
