import GoogleMobileAds
import Observation
import UserMessagingPlatform

@MainActor
@Observable
final class AdsPrivacyController {
    private(set) var canRequestAds = false
    private(set) var isPrivacyOptionsRequired = false
    private(set) var adGeneration = 0
    var privacyOptionsError: String?
    private var hasRequestedConsent = false
    private var hasStartedAds = false

    func prepare() async {
        guard !hasRequestedConsent else { return }
        hasRequestedConsent = true
        MobileAds.shared.requestConfiguration.setPublisherFirstPartyIDEnabled(false)
        MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState = .disabled
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            // A consent/network error never prevents users from taking a quiz.
            #if DEBUG
            print("Consent update: \(error.localizedDescription)")
            #endif
        }
        refreshEligibility()
    }

    func presentPrivacyOptions() async {
        guard isPrivacyOptionsRequired else { return }
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        } catch {
            privacyOptionsError = "広告の選択画面を開けませんでした。通信状態を確認し、もう一度お試しください。"
        }
        adGeneration += 1
        refreshEligibility()
    }

    private func refreshEligibility() {
        let eligible = ConsentInformation.shared.canRequestAds
        isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        if eligible && !hasStartedAds {
            hasStartedAds = true
            MobileAds.shared.start()
        }
        canRequestAds = eligible
    }
}
