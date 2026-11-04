import GoogleMobileAds
import SwiftUI

@main
struct NihonshuQuizApp: App {
    @State private var adsPrivacy = AdsPrivacyController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.shu)
                .preferredColorScheme(.light)
                .environment(adsPrivacy)
                .task { await adsPrivacy.prepare() }
        }
    }
}
