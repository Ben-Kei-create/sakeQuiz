import Foundation
import Observation

@Observable
final class ProgressStore {
    static let stateKey = "kome.state.v1"
    private static let backupKey = "kome.state.v1.backup"
    private static let corruptKey = "kome.state.v1.corrupt"

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored let totalDays: Int

    private(set) var state: ProgressState
    /// 保存データが壊れていて、バックアップまたは空から復旧した。
    private(set) var recoveredFromCorruption = false

    init(totalDays: Int, defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.totalDays = totalDays
        self.defaults = defaults
        self.calendar = calendar
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: Self.stateKey) {
            if let decoded = try? decoder.decode(ProgressState.self, from: data) {
                state = decoded
            } else {
                defaults.set(data, forKey: Self.corruptKey)
                recoveredFromCorruption = true
                state = defaults.data(forKey: Self.backupKey).flatMap { try? decoder.decode(ProgressState.self, from: $0) } ?? ProgressState()
            }
        } else {
            state = ProgressState()
        }
    }

    // MARK: - 仕込み暦

    var completedCount: Int { state.completions.count }

    var lastCompletionKey: String? { state.completions.values.max() }

    /// 次に仕込む日の通し番号。すべて終えたら nil。
    var nextLessonDay: Int? {
        let next = (1...max(totalDays, 1)).first { state.completions[$0] == nil }
        return totalDays > 0 ? next : nil
    }

    /// 今日、仕込めるか。1日1回。端末の日付を戻しても、直近の完了日より後でなければ開かない。
    func isTodayOpen(on date: Date = .now) -> Bool {
        guard nextLessonDay != nil else { return false }
        guard let last = lastCompletionKey else { return true }
        return DayKey.key(for: date, calendar: calendar) > last
    }

    @discardableResult
    func completeLesson(day: Int, on date: Date = .now) -> Bool {
        guard isTodayOpen(on: date), day == nextLessonDay else { return false }
        state.completions[day] = DayKey.key(for: date, calendar: calendar)
        save()
        return true
    }

    /// 連続して仕込んだ日数。今日か昨日までつながっていれば数える。
    func streak(on date: Date = .now) -> Int {
        let days = Set(state.completions.values)
        let today = DayKey.key(for: date, calendar: calendar)
        var cursor = days.contains(today) ? today : DayKey.adding(days: -1, to: today, calendar: calendar)
        var count = 0
        while days.contains(cursor) {
            count += 1
            cursor = DayKey.adding(days: -1, to: cursor, calendar: calendar)
        }
        return count
    }

    // MARK: - 回答と復習

    /// 仕込みの確認問題に答えた。間違えたら、翌日の復習に入れる。
    func recordLessonAnswer(questionID: String, isCorrect: Bool, on date: Date = .now) {
        state.answered += 1
        if isCorrect {
            state.correct += 1
        } else {
            state.wrongCounts[questionID, default: 0] += 1
            state.reviews[questionID] = ReviewEntry(stage: 0, dueOn: dayKey(offset: 1, from: date))
        }
        save()
    }

    /// 復習に答えた。正解で間隔が延び、3回正解すると卒業する。
    func recordReviewAnswer(questionID: String, isCorrect: Bool, on date: Date = .now) {
        state.answered += 1
        guard var entry = state.reviews[questionID] else {
            if isCorrect { state.correct += 1 }
            save()
            return
        }
        if isCorrect {
            state.correct += 1
            entry.stage += 1
            if entry.stage >= ReviewSchedule.intervals.count {
                state.reviews[questionID] = nil
            } else {
                entry.dueOn = dayKey(offset: ReviewSchedule.intervals[entry.stage], from: date)
                state.reviews[questionID] = entry
            }
        } else {
            state.wrongCounts[questionID, default: 0] += 1
            state.reviews[questionID] = ReviewEntry(stage: 0, dueOn: dayKey(offset: 1, from: date))
        }
        save()
    }

    /// 今日の復習。間違えた回数が多い順。
    func dueReviewIDs(on date: Date = .now) -> [String] {
        let today = DayKey.key(for: date, calendar: calendar)
        return state.reviews
            .filter { $0.value.dueOn <= today }
            .map(\.key)
            .sorted { (state.wrongCounts[$0] ?? 0, $1) > (state.wrongCounts[$1] ?? 0, $0) }
    }

    // MARK: - 蔵印帳

    @discardableResult
    func awardSeal(_ sealID: String, on date: Date = .now) -> Bool {
        guard state.seals[sealID] == nil else { return false }
        state.seals[sealID] = DayKey.key(for: date, calendar: calendar)
        save()
        return true
    }

    func reset() {
        state = ProgressState()
        defaults.removeObject(forKey: Self.stateKey)
        defaults.removeObject(forKey: Self.backupKey)
        defaults.removeObject(forKey: Self.corruptKey)
    }

    // MARK: - 保存

    private func dayKey(offset: Int, from date: Date) -> String {
        DayKey.adding(days: offset, to: DayKey.key(for: date, calendar: calendar), calendar: calendar)
    }

    private func save() {
        if let previous = defaults.data(forKey: Self.stateKey) {
            defaults.set(previous, forKey: Self.backupKey)
        }
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: Self.stateKey)
        }
    }
}
