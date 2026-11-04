import AudioToolbox
import UIKit

enum SoundPlayer {
    static let soundEnabledKey = "nihonshuquiz.soundEnabled"
    static let hapticsEnabledKey = "nihonshuquiz.hapticsEnabled"

    private static var isSoundEnabled: Bool {
        UserDefaults.standard.object(forKey: soundEnabledKey) as? Bool ?? true
    }

    private static var isHapticsEnabled: Bool {
        UserDefaults.standard.object(forKey: hapticsEnabledKey) as? Bool ?? true
    }

    static func playCorrect() {
        play(1057)
        notify(.success)
    }

    static func playIncorrect() {
        play(1053)
        notify(.error)
    }

    static func playFinish() {
        play(1025)
    }

    private static func play(_ soundID: SystemSoundID) {
        guard isSoundEnabled else {
            return
        }

        AudioServicesPlaySystemSound(soundID)
    }

    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else {
            return
        }

        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
