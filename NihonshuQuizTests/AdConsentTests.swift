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

    func testBannerUsesGoogleTestUnitUntilOwnIDIsIssued() {
        XCTAssertTrue(AdUnit.banner.hasPrefix("ca-app-pub-3940256099942544/"), "テストID以外が入っている")
        XCTAssertFalse(AdUnit.banner.contains("4859622277330192"), "ワイン版のIDは使わない")
    }
}
