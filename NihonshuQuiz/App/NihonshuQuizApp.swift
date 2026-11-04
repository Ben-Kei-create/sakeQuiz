import GoogleMobileAds
import SwiftUI

@main
struct NihonshuQuizApp: App {
    @State private var consent = AdConsent()

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.shu)
                .preferredColorScheme(.light)
                .environment(consent)
                .task { await consent.resolve() }
        }
    }
}
