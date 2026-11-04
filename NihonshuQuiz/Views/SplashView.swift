import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void
    var body: some View {
        ZStack {
            NihonshuTheme.indigo.ignoresSafeArea()
            VStack(spacing: 24) {
                SakeMark().frame(width: 120, height: 150)
                Text("日本酒雑学クイズ").font(.title.bold()).foregroundStyle(NihonshuTheme.kinari).multilineTextAlignment(.center)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled else { return }
            onFinish()
        }
    }
}
