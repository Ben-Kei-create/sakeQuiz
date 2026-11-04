import GoogleMobileAds
import SwiftUI

@main
struct NihonshuQuizApp: App {
    @State private var consent = AdConsent()
    @State private var reminder = ReminderCenter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.shu)
                .preferredColorScheme(.light)
                .environment(consent)
                .environment(reminder)
                .task { await consent.resolve() }
        }
    }
}
