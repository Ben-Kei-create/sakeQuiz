
import GoogleMobileAds
import SwiftUI

enum AdMobConfiguration {
    #if DEBUG
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    #else
    // TODO: 日本酒版専用のバナー広告ユニットIDが発行されるまでは、Google公式テストIDのまま。
    // ワイン版のIDは再利用しない。本番IDへの切り替えは、ユーザー確認後に行う。
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    #endif

}

struct AdBannerBar: View {
    @Environment(AdsPrivacyController.self) private var adsPrivacy
    @State private var adHeight: CGFloat = 50

    var body: some View {
        if adsPrivacy.canRequestAds {
            HStack {
                Spacer(minLength: 0)
                BannerViewContainer(onHeightChange: { height in
                    adHeight = height
                })
                .frame(height: adHeight)
                .id(adsPrivacy.adGeneration)
                .accessibilityIdentifier("quiz_banner_ad")
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.08))
        }
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    let onHeightChange: (CGFloat) -> Void

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdMobConfiguration.bannerAdUnitID
        banner.delegate = context.coordinator
        let request = Request()
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        banner.load(request)
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {}

    func makeCoordinator() -> BannerCoordinator {
        BannerCoordinator(onHeightChange: onHeightChange)
    }

    final class BannerCoordinator: NSObject, BannerViewDelegate {
        let onHeightChange: (CGFloat) -> Void

        init(onHeightChange: @escaping (CGFloat) -> Void) {
            self.onHeightChange = onHeightChange
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            onHeightChange(bannerView.adSize.size.height)
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            #if DEBUG
            print("Banner ad failed to load: \(error.localizedDescription)")
            #endif
        }
    }
}
