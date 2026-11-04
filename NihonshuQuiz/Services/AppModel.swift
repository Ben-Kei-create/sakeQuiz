import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    let library: ContentLibrary?
    let loadError: String?
    let store: ProgressStore
    /// 画面が見ている「いま」。日付をまたいだ時に更新する。
    private(set) var now: Date
    @ObservationIgnored private let dayOffset: Int

    init(defaults: UserDefaults = .standard, bundle: Bundle = .main, arguments: [String] = ProcessInfo.processInfo.arguments) {
        var offset = 0
        var defaults = defaults
        #if DEBUG
        let screenshotMode = arguments.contains("-SCREENSHOT_MODE")
        if screenshotMode {
            // 撮影専用：専用の保存領域を空にして、エンジン経由で、44日分の記録を作る。出荷版には入らない。
            let suite = "kome.screenshot"
            let shot = UserDefaults(suiteName: suite)!
            shot.removePersistentDomain(forName: suite)
            defaults = shot
        } else if arguments.contains("-ui-testing") {
            let suite = "kome.ui-tests"
            let testDefaults = UserDefaults(suiteName: suite)!
            if !arguments.contains("-ui-keep-state") { testDefaults.removePersistentDomain(forName: suite) }
            defaults = testDefaults
        }
        if let i = arguments.firstIndex(of: "-ui-day-offset"), arguments.indices.contains(i + 1) {
            offset = Int(arguments[i + 1]) ?? 0
        }
        #endif
        dayOffset = offset
        do {
            let loaded = try ContentLibrary.load(from: bundle)
            library = loaded
            loadError = nil
            store = ProgressStore(totalDays: loaded.lessons.count, defaults: defaults)
        } catch {
            library = nil
            loadError = error.localizedDescription
            store = ProgressStore(totalDays: 0, defaults: defaults)
        }
        now = Calendar.current.date(byAdding: .day, value: offset, to: .now) ?? .now
        #if DEBUG
        if screenshotMode, let library {
            var days = 44
            if let i = arguments.firstIndex(of: "-SCREENSHOT_DAYS"), arguments.indices.contains(i + 1), let n = Int(arguments[i + 1]) { days = n }
            Self.seedScreenshotProgress(library: library, store: store, days: days)
        }
        #endif
    }

    #if DEBUG
    /// 撮影用：44日分を、昨日までに仕込んだ状態にする。41日目の問いのうち2問は、間違えた扱いにして、復習を出す。
    private static func seedScreenshotProgress(library: ContentLibrary, store: ProgressStore, days: Int = 44) {
        let calendar = Calendar.current
        for day in 1...days {
            guard let lesson = library.lesson(day: day),
                  let date = calendar.date(byAdding: .day, value: -(days + 1 - day), to: .now) else { continue }
            for (i, id) in lesson.questionIDs.enumerated() {
                let wrong = day == min(41, days) && i < 2
                store.recordLessonAnswer(questionID: id, isCorrect: !wrong, on: date)
                if !wrong, let seal = library.seal(forQuestion: id) { store.awardSeal(seal.id, on: date) }
            }
            store.completeLesson(day: day, on: date)
        }
    }
    #endif

    func refreshClock() {
        now = Calendar.current.date(byAdding: .day, value: dayOffset, to: .now) ?? .now
    }

    var isTodayOpen: Bool { store.isTodayOpen(on: now) }
}
