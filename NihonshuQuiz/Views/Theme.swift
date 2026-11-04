import SwiftUI
import UIKit

/// 系統A（Paper & Editorial）、Era＝明治。影とグラデーションは使わない。
enum Theme {
    static let washi = Color(red: 0.980, green: 0.969, blue: 0.949)      // #FAF7F2 和紙
    static let washiDeep = Color(red: 0.914, green: 0.882, blue: 0.827)  // #E9E1D3 淡い和紙
    static let sumi = Color(red: 0.271, green: 0.255, blue: 0.235)       // #45413C 墨
    static let shu = Color(red: 0.761, green: 0.322, blue: 0.075)        // #C25214 朱（判・印）
    /// 朱の文字用（和紙の上でコントラスト比4.5以上になるよう、少し暗くする）。
    static let shuText = Color(red: 0.690, green: 0.267, blue: 0.039)    // #B0440A

    static let spacing: (s: CGFloat, m: CGFloat, l: CGFloat, xl: CGFloat) = (8, 16, 24, 32)
    static let corner: CGFloat = 6
}

extension Font {
    /// 日本語は Shippori Mincho、英数は Source Serif 4。読み込めなければシステム書体。
    static func mincho(_ size: CGFloat, bold: Bool = false, relativeTo style: Font.TextStyle = .body) -> Font {
        let name = bold ? "ShipporiMincho-Bold" : "ShipporiMincho-Regular"
        return UIFont(name: name, size: size) != nil
            ? .custom(name, size: size, relativeTo: style)
            : .system(style, design: .serif, weight: bold ? .bold : .regular)
    }

    static func numeral(_ size: CGFloat, semibold: Bool = true, relativeTo style: Font.TextStyle = .title) -> Font {
        let name = semibold ? "SourceSerif4-Semibold" : "SourceSerif4-Regular"
        return UIFont(name: name, size: size) != nil
            ? .custom(name, size: size, relativeTo: style)
            : .system(style, design: .serif, weight: semibold ? .semibold : .regular).monospacedDigit()
    }
}

/// 朱の判。完了・印に使う。
struct Seal: View {
    let text: String
    var size: CGFloat = 56
    var body: some View {
        Text(text)
            .font(.mincho(size * 0.34, bold: true, relativeTo: .caption))
            .foregroundStyle(Theme.washi)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .padding(.horizontal, size * 0.08)
            .frame(width: size, height: size)
            .background(Theme.shu, in: Circle())
            .accessibilityHidden(true)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.mincho(17, bold: true, relativeTo: .headline))
            .foregroundStyle(Theme.washi)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, Theme.spacing.m)
            .background(Theme.sumi, in: RoundedRectangle(cornerRadius: Theme.corner))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct LinedPage<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .padding(Theme.spacing.m)
            .overlay { RoundedRectangle(cornerRadius: Theme.corner).stroke(Theme.sumi.opacity(0.35), lineWidth: 1) }
    }
}

/// 挿絵。画像が `Assets.xcassets` に入っていれば出し、なければ何も出さない（代わりの判などは、呼び出し側で置く）。
struct Illustration: View {
    let name: String
    var height: CGFloat = 140

    static func exists(_ name: String) -> Bool { UIImage(named: name) != nil }

    var body: some View {
        if Self.exists(name) {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(height: height)
                .accessibilityHidden(true)
        }
    }
}
