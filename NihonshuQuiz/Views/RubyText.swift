import CoreText
import SwiftUI
import UIKit

extension RubyAnnotator {
    /// アプリ全体で使う、ふりがなの辞書。
    static let shared = RubyAnnotator.load()
}

enum Furigana {
    static let enabledKey = "kome.furigana"
}

/// 1行目のふりがなが、上で切れないように、上に余白を持つラベル。
private final class RubyLabel: UILabel {
    var topInset: CGFloat = 0

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)))
    }
}

/// ふりがな付きの文章。難しい言葉には、最初の1回だけ、読みを付ける。
/// 文字の大きさは、端末の設定（Dynamic Type）に追従する。VoiceOverには、読みに置き換えた文を渡す。
struct RubyText: UIViewRepresentable {
    let text: String
    var size: CGFloat = 17
    var bold = false
    var style: UIFont.TextStyle = .body
    var color: Color = Theme.sumi

    @AppStorage(Furigana.enabledKey) private var furiganaEnabled = true
    @Environment(\.sizeCategory) private var sizeCategory

    func makeUIView(context: Context) -> UILabel {
        let label = RubyLabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = .clear
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.isAccessibilityElement = true
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        let annotator = RubyAnnotator.shared
        let segments = furiganaEnabled ? annotator.segments(in: text) : [.init(base: text, reading: nil)]
        label.attributedText = attributed(segments)
        (label as? RubyLabel)?.topInset = segments.contains { $0.reading != nil } ? scaledFont().pointSize * 0.6 : 0
        label.accessibilityLabel = furiganaEnabled ? annotator.spokenText(for: text) : text
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        let width = proposal.width ?? 320
        uiView.preferredMaxLayoutWidth = width
        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let inset = (uiView as? RubyLabel)?.topInset ?? 0
        return CGSize(width: width, height: ceil(fitted.height + inset))
    }

    private func scaledFont() -> UIFont {
        let name = bold ? "ShipporiMincho-Bold" : "ShipporiMincho-Regular"
        let base = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size, weight: bold ? .bold : .regular)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
    }

    private func attributed(_ segments: [RubyAnnotator.Segment]) -> NSAttributedString {
        let font = scaledFont()
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = font.pointSize * (segments.contains { $0.reading != nil } ? 0.75 : 0.45)
        let result = NSMutableAttributedString()
        for segment in segments {
            var attributes: [NSAttributedString.Key: Any] = [
                .font: font, .foregroundColor: UIColor(color), .paragraphStyle: paragraph,
            ]
            if let reading = segment.reading {
                let ruby = CTRubyAnnotationCreateWithAttributes(
                    .center, .auto, .before, reading as CFString,
                    [kCTRubyAnnotationSizeFactorAttributeName: 0.5] as CFDictionary
                )
                attributes[NSAttributedString.Key(kCTRubyAnnotationAttributeName as String)] = ruby
            }
            result.append(NSAttributedString(string: segment.base, attributes: attributes))
        }
        return result
    }
}
