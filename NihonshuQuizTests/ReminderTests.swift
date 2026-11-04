import XCTest
@testable import NihonshuQuiz

private final class FakeScheduler: NotificationScheduling {
    var state: ReminderAuthorization = .notDetermined
    var grants = true
    var requested = 0
    var scheduled: [String] = []

    func authorizationState() async -> ReminderAuthorization { state }
    func requestAuthorization() async -> Bool { requested += 1; return grants }
    func replacePending(prefix: String, with requests: [(id: String, components: DateComponents, title: String, body: String)]) async {
        scheduled = requests.map(\.id)
    }
}

@MainActor
final class ReminderTests: XCTestCase {
    private var calendar: Calendar!
    private var defaults: UserDefaults!
    private var suite: String!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        suite = "ReminderTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private func date(_ key: String, hour: Int) -> Date {
        DayKey.date(from: key, calendar: calendar)!.addingTimeInterval(TimeInterval(hour * 3600))
    }

    func testPlanSkipsPastTimeAndTodayWhenAlreadyDone() {
        let evening = ReminderPlan.fireDates(now: date("2026-11-04", hour: 20), hour: 19, minute: 0, completedToday: false, allFinished: false, days: 3, calendar: calendar)
        XCTAssertEqual(evening.map(\.day), [5, 6], "19時を過ぎたので、今日は出さない")
        let morning = ReminderPlan.fireDates(now: date("2026-11-04", hour: 8), hour: 19, minute: 0, completedToday: false, allFinished: false, days: 3, calendar: calendar)
        XCTAssertEqual(morning.map(\.day), [4, 5, 6])
        let done = ReminderPlan.fireDates(now: date("2026-11-04", hour: 8), hour: 19, minute: 0, completedToday: true, allFinished: false, days: 3, calendar: calendar)
        XCTAssertEqual(done.map(\.day), [5, 6], "今日は終えたので、出さない")
        XCTAssertTrue(ReminderPlan.fireDates(now: date("2026-11-04", hour: 8), hour: 19, minute: 0, completedToday: false, allFinished: true, calendar: calendar).isEmpty)
    }

    func testPlanCrossesMonthEnd() {
        let plan = ReminderPlan.fireDates(now: date("2026-11-29", hour: 8), hour: 19, minute: 30, completedToday: false, allFinished: false, days: 3, calendar: calendar)
        XCTAssertEqual(plan.map(\.month), [11, 11, 12])
        XCTAssertEqual(plan.map(\.day), [29, 30, 1])
        XCTAssertEqual(plan.first?.minute, 30)
    }

    func testOfferComesOnlyAfterThreeDaysAndOnlyOnce() async {
        let center = ReminderCenter(defaults: defaults, scheduler: FakeScheduler(), calendar: calendar)
        XCTAssertFalse(center.shouldOffer(completedDays: 2))
        XCTAssertTrue(center.shouldOffer(completedDays: 3))
        center.declineOffer()
        XCTAssertFalse(center.shouldOffer(completedDays: 10), "一度断られたら、頼まない")
        XCTAssertTrue(ReminderCenter(defaults: defaults, scheduler: FakeScheduler(), calendar: calendar).hasAsked, "再起動しても、覚えている")
    }

    func testEnableAsksPermissionAndRespectsDenial() async {
        let fake = FakeScheduler()
        let center = ReminderCenter(defaults: defaults, scheduler: fake, calendar: calendar)
        fake.grants = false
        let denied = await center.enable()
        XCTAssertFalse(denied)
        XCTAssertFalse(center.isEnabled)
        XCTAssertEqual(center.authorization, .denied)

        let fake2 = FakeScheduler(); fake2.grants = true
        let center2 = ReminderCenter(defaults: UserDefaults(suiteName: suite + "2")!, scheduler: fake2, calendar: calendar)
        let granted = await center2.enable()
        XCTAssertTrue(granted)
        XCTAssertEqual(fake2.requested, 1)
        UserDefaults().removePersistentDomain(forName: suite + "2")
    }

    func testRescheduleReplacesPendingAndStopsWhenAuthorizationIsRevoked() async {
        let fake = FakeScheduler(); fake.state = .allowed
        let center = ReminderCenter(defaults: defaults, scheduler: fake, calendar: calendar)
        await center.enable()
        let store = ProgressStore(totalDays: 5, defaults: defaults, calendar: calendar)
        await center.reschedule(store: store, now: date("2026-11-04", hour: 8))
        XCTAssertEqual(fake.scheduled.count, 14)
        XCTAssertTrue(fake.scheduled.first?.hasPrefix(ReminderCenter.idPrefix) == true)

        fake.state = .denied
        await center.reschedule(store: store, now: date("2026-11-04", hour: 8))
        XCTAssertFalse(center.isEnabled, "端末の設定で止められたら、有効にしない")
    }

    func testDisableClearsPending() async {
        let fake = FakeScheduler(); fake.state = .allowed
        let center = ReminderCenter(defaults: defaults, scheduler: fake, calendar: calendar)
        await center.enable()
        let store = ProgressStore(totalDays: 5, defaults: defaults, calendar: calendar)
        await center.reschedule(store: store, now: date("2026-11-04", hour: 8))
        await center.disable()
        XCTAssertTrue(fake.scheduled.isEmpty)
        XCTAssertFalse(center.isEnabled)
    }
}
