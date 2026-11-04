import Foundation
import Observation
import UserNotifications

/// 通知を出す日時の計画。端末の中だけで動く、ローカル通知。
enum ReminderPlan {
    /// 今日の仕込みを終えていれば今日は出さない。時刻を過ぎていれば、今日は出さない。すべて終えていれば出さない。
    static func fireDates(now: Date, hour: Int, minute: Int, completedToday: Bool, allFinished: Bool,
                          days: Int = 14, calendar: Calendar = .current) -> [DateComponents] {
        guard !allFinished else { return [] }
        var result: [DateComponents] = []
        let start = calendar.startOfDay(for: now)
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start),
                  let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  fire > now else { continue }
            if offset == 0 && completedToday { continue }
            result.append(calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire))
        }
        return result
    }
}

/// 通知センターの、必要な部分だけ。試験では、これを差し替える。
protocol NotificationScheduling {
    func authorizationState() async -> ReminderAuthorization
    func requestAuthorization() async -> Bool
    func replacePending(prefix: String, with requests: [(id: String, components: DateComponents, title: String, body: String)]) async
}

enum ReminderAuthorization: Equatable { case notDetermined, denied, allowed }

struct SystemNotificationScheduler: NotificationScheduling {
    private var center: UNUserNotificationCenter { .current() }

    func authorizationState() async -> ReminderAuthorization {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: return .notDetermined
        case .authorized, .provisional, .ephemeral: return .allowed
        default: return .denied
        }
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func replacePending(prefix: String, with requests: [(id: String, components: DateComponents, title: String, body: String)]) async {
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) })
        for r in requests {
            let content = UNMutableNotificationContent()
            content.title = r.title
            content.body = r.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: r.components, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: r.id, content: content, trigger: trigger))
        }
    }
}

@MainActor
@Observable
final class ReminderCenter {
    private enum Key {
        static let enabled = "kome.reminder.enabled"
        static let hour = "kome.reminder.hour"
        static let minute = "kome.reminder.minute"
        static let asked = "kome.reminder.asked"
    }
    static let idPrefix = "kome.reminder."
    static let offerAfterCompletedDays = 3

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let scheduler: NotificationScheduling
    @ObservationIgnored private let calendar: Calendar

    private(set) var isEnabled: Bool
    private(set) var hour: Int
    private(set) var minute: Int
    private(set) var hasAsked: Bool
    private(set) var authorization: ReminderAuthorization = .notDetermined

    init(defaults: UserDefaults = .standard, scheduler: NotificationScheduling = SystemNotificationScheduler(), calendar: Calendar = .current) {
        self.defaults = defaults
        self.scheduler = scheduler
        self.calendar = calendar
        isEnabled = defaults.bool(forKey: Key.enabled)
        hour = defaults.object(forKey: Key.hour) as? Int ?? 19
        minute = defaults.object(forKey: Key.minute) as? Int ?? 0
        hasAsked = defaults.bool(forKey: Key.asked)
    }

    /// 価値を体験した3日目以降に、1回だけ、お知らせを頼む。
    func shouldOffer(completedDays: Int) -> Bool {
        completedDays >= Self.offerAfterCompletedDays && !hasAsked && !isEnabled && authorization == .notDetermined
    }

    func declineOffer() {
        hasAsked = true
        defaults.set(true, forKey: Key.asked)
    }

    /// 許可を求め、通った場合だけ、お知らせを有効にする。
    @discardableResult
    func enable() async -> Bool {
        hasAsked = true
        defaults.set(true, forKey: Key.asked)
        var state = await scheduler.authorizationState()
        if state == .notDetermined { state = await scheduler.requestAuthorization() ? .allowed : .denied }
        authorization = state
        isEnabled = state == .allowed
        defaults.set(isEnabled, forKey: Key.enabled)
        return isEnabled
    }

    func disable() async {
        isEnabled = false
        defaults.set(false, forKey: Key.enabled)
        await scheduler.replacePending(prefix: Self.idPrefix, with: [])
    }

    func setTime(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
        defaults.set(hour, forKey: Key.hour)
        defaults.set(minute, forKey: Key.minute)
    }

    func refreshAuthorization() async {
        authorization = await scheduler.authorizationState()
        if isEnabled && authorization != .allowed {
            isEnabled = false
            defaults.set(false, forKey: Key.enabled)
        }
    }

    /// 今後2週間分の通知を、計画しなおす。仕込みを終えた時、起動した時、設定を変えた時に呼ぶ。
    func reschedule(store: ProgressStore, now: Date = .now) async {
        await refreshAuthorization()
        guard isEnabled else { return }
        let today = DayKey.key(for: now, calendar: calendar)
        let plan = ReminderPlan.fireDates(
            now: now, hour: hour, minute: minute,
            completedToday: store.lastCompletionKey == today,
            allFinished: store.nextLessonDay == nil, calendar: calendar)
        let requests = plan.map { c in
            (id: Self.idPrefix + String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0), components: c,
             title: "蔵ごよみ", body: "本日の仕込み、まだです。")
        }
        await scheduler.replacePending(prefix: Self.idPrefix, with: requests)
    }
}
