import SwiftUI

/// 内容を読み込めなかった時の画面。
struct UnavailableView: View {
    let message: String

    var body: some View {
        VStack(spacing: Theme.spacing.m) {
            Seal(text: "不具合", size: 72)
            Text("帳面を開けません")
                .font(.mincho(22, bold: true, relativeTo: .title2))
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.mincho(15))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Theme.sumi)
        .padding(Theme.spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.washi)
    }
}
