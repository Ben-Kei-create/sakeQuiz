import Foundation

/// 「年-月-日」の文字列。辞書順がそのまま日付順になる。
enum DayKey {
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func date(from key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    static func adding(days: Int, to key: String, calendar: Calendar = .current) -> String {
        guard let base = date(from: key, calendar: calendar),
              let shifted = calendar.date(byAdding: .day, value: days, to: base) else { return key }
        return Self.key(for: shifted, calendar: calendar)
    }
}
