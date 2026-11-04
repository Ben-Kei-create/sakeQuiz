import GoogleMobileAds
import Observation
import UserMessagingPlatform

/// 広告を出してよいかの判断。同意の確認（UMP）が済み、許可された時だけ広告SDKを動かす。
/// 同意できない、通信できない場合も、読み物・復習など、アプリの機能はすべて使える。
@MainActor
@Observable
final class AdConsent {
    enum Phase: Equatable {
        case notStarted
        case resolving
        /// 広告を出してよい。
        case allowed
        /// 広告は出さない（同意が得られない、または確認できなかった）。
        case withheld
    }

    private(set) var phase: Phase = .notStarted
    /// 設定に「広告のプライバシー設定」を出すか。
    private(set) var offersChoices = false
    /// 選択を変えると、バナーを作り直す合図に使う。
    private(set) var choiceRevision = 0
    var alertMessage: String?

    private var sdkStarted = false

    var showsAds: Bool { phase == .allowed }

    func resolve() async {
        guard phase == .notStarted else { return }
        phase = .resolving
        let settings = MobileAds.shared.requestConfiguration
        settings.setPublisherFirstPartyIDEnabled(false)
        settings.publisherPrivacyPersonalizationState = .disabled
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            #if DEBUG
            print("同意の確認に失敗：\(error.localizedDescription)")
            #endif
        }
        applyCurrentStatus()
    }

    func reopenChoices() async {
        guard offersChoices else { return }
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        } catch {
            alertMessage = "広告の選択画面を開けなかった。通信の状態を確かめて、もう一度試してほしい。"
        }
        choiceRevision += 1
        applyCurrentStatus()
    }

    private func applyCurrentStatus() {
        let info = ConsentInformation.shared
        offersChoices = info.privacyOptionsRequirementStatus == .required
        if info.canRequestAds {
            if !sdkStarted {
                sdkStarted = true
                MobileAds.shared.start()
            }
            phase = .allowed
        } else {
            phase = .withheld
        }
    }
}
