import UIKit

/// 触覚だけの手応え。音は使わない。
enum Feedback {
    static let hapticsKey = "kome.hapticsEnabled"

    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: hapticsKey) as? Bool ?? true
    }

    static func answered(correct: Bool) {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .warning)
    }

    static func stamped() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
