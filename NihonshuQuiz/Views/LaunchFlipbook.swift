import SwiftUI
import UIKit

/// 起動時の、パラパラ漫画。`Assets.xcassets` の `splash_1`、`splash_2`… を、順に切り替えて見せる。
/// 画像が1枚もなければ、出さない。タップで飛ばせる。「視差効果を減らす」の時は、最後の1枚だけを短く見せる。VoiceOverの時は、出さない。
struct LaunchFlipbook: View {
    static let framePrefix = "splash_"
    static let frameDuration: Duration = .milliseconds(140)

    /// 入っている画像の名前（連番が途切れるまで）。
    static func frameNames() -> [String] {
        var names: [String] = []
        var i = 1
        while UIImage(named: "\(framePrefix)\(i)") != nil { names.append("\(framePrefix)\(i)"); i += 1 }
        return names
    }

    /// 出してよいか（撮影・試験の時は出さない。画像がなければ出さない）。
    static func shouldShow(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        #if DEBUG
        if arguments.contains("-ui-testing") || arguments.contains("-SCREENSHOT_MODE") { return false }
        #endif
        return !frameNames().isEmpty && !UIAccessibility.isVoiceOverRunning
    }

    let onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frames: [String] = frameNames()
    @State private var index = 0

    var body: some View {
        ZStack {
            Theme.washi.ignoresSafeArea()
            if frames.indices.contains(index) {
                Image(frames[index])
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 360, maxHeight: 360)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onFinish() }
        .task {
            guard !frames.isEmpty else { onFinish(); return }
            if reduceMotion {
                index = frames.count - 1
                try? await Task.sleep(for: .milliseconds(500))
            } else {
                for i in frames.indices {
                    index = i
                    try? await Task.sleep(for: Self.frameDuration)
                    if Task.isCancelled { return }
                }
                try? await Task.sleep(for: .milliseconds(250))
            }
            onFinish()
        }
    }
}
