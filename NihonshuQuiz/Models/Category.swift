import Foundation

enum QuizCategory: String, CaseIterable, Codable, Hashable, Identifiable {
    case rice
    case grade
    case brewing
    case yeastWater
    case region
    case taste
    case pairing
    case historyLabel

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .rice: return "米と酒米"
        case .grade: return "精米歩合と特定名称"
        case .brewing: return "醸造工程"
        case .yeastWater: return "酵母と水"
        case .region: return "産地と酒蔵の文化"
        case .taste: return "味わい・温度・酒器"
        case .pairing: return "ペアリング"
        case .historyLabel: return "歴史・表示・保存"
        }
    }

    var symbolName: String {
        switch self {
        case .rice: return "leaf"
        case .grade: return "circle.dashed"
        case .brewing: return "flask"
        case .yeastWater: return "drop"
        case .region: return "map"
        case .taste: return "thermometer.medium"
        case .pairing: return "fork.knife"
        case .historyLabel: return "text.book.closed"
        }
    }
}
