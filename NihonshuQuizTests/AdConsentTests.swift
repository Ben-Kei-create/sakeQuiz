import XCTest
@testable import NihonshuQuiz

@MainActor
final class AdConsentTests: XCTestCase {
    func testNoAdsBeforeConsentIsResolved() {
        let consent = AdConsent()
        XCTAssertEqual(consent.phase, .notStarted)
        XCTAssertFalse(consent.showsAds)
        XCTAssertFalse(consent.offersChoices)
    }

    func testDebugBuildsUseGoogleTestUnit() {
        XCTAssertTrue(AdUnit.banner.hasPrefix("ca-app-pub-3940256099942544/"), "Debugはテストを使う")
    }

    func testProductionUnitIsNotTheWineAppsUnit() {
        let wineUnit = "ca-app-pub-4859622277330192/3016344791"
        XCTAssertNotEqual(AdUnit.productionBanner, wineUnit, "ワイン版の広告ユニットは使わない")
        XCTAssertTrue(AdUnit.productionBanner.hasPrefix("ca-app-pub-4859622277330192/"))
    }
}
