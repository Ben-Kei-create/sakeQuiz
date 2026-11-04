import GoogleMobileAds
import SwiftUI

/// 広告ユニットのID。日本酒版（蔵ごよみ）のIDが発行されるまでは、Google公式のテストIDを使う。
enum AdUnit {
    static let banner = "ca-app-pub-3940256099942544/2934735716"
}

/// 画面の下に置くバナー。同意が得られていない間は、何も出さず、場所も取らない。
/// 置く場所は、仕込み暦のホームと、完了画面だけ。回答中には出さない。
struct BannerSlot: View {
    @Environment(AdConsent.self) private var consent
    @State private var height: CGFloat = 50

    var body: some View {
        if consent.showsAds {
            BannerHost(unitID: AdUnit.banner) { height = $0 }
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .background(Theme.washiDeep)
                .id(consent.choiceRevision)
                .accessibilityIdentifier("banner_slot")
        }
    }
}

private struct BannerHost: UIViewRepresentable {
    let unitID: String
    let onHeight: (CGFloat) -> Void

    func makeCoordinator() -> Listener { Listener(onHeight: onHeight) }

    func makeUIView(context: Context) -> BannerView {
        let view = BannerView(adSize: AdSizeBanner)
        view.adUnitID = unitID
        view.delegate = context.coordinator
        view.load(Self.nonPersonalizedRequest())
        return view
    }

    func updateUIView(_ view: BannerView, context: Context) {}

    /// 非パーソナライズ広告を求める。
    private static func nonPersonalizedRequest() -> Request {
        let request = Request()
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        return request
    }

    final class Listener: NSObject, BannerViewDelegate {
        let onHeight: (CGFloat) -> Void
        init(onHeight: @escaping (CGFloat) -> Void) { self.onHeight = onHeight }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            onHeight(bannerView.adSize.size.height)
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            #if DEBUG
            print("バナーを読み込めなかった：\(error.localizedDescription)")
            #endif
        }
    }
}
