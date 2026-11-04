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
        if arguments.contains("-ui-testing") {
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
    }

    func refreshClock() {
        now = Calendar.current.date(byAdding: .day, value: dayOffset, to: .now) ?? .now
    }

    var isTodayOpen: Bool { store.isTodayOpen(on: now) }
}
