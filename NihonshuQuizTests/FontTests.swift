import XCTest
import UIKit
@testable import NihonshuQuiz

final class FontTests: XCTestCase {
    func testBundledFontsAreRegistered() {
        for name in ["ShipporiMincho-Regular", "ShipporiMincho-Bold", "SourceSerif4-Regular", "SourceSerif4-Semibold"] {
            XCTAssertNotNil(UIFont(name: name, size: 16), "\(name) が読み込めない")
        }
    }

    func testBundledMinchoCoversTheCharactersWeUse() {
        let font = UIFont(name: "ShipporiMincho-Regular", size: 16)!
        for ch in "仕込み帳麹酛醪杜氏蔵印朱判精米歩合吟醸酒" {
            var glyph = [CGGlyph](repeating: 0, count: 1)
            var chars = Array(String(ch).utf16)
            XCTAssertTrue(CTFontGetGlyphsForCharacters(font, &chars, &glyph, 1), "\(ch) がフォントにない")
        }
    }

    /// 読み物・問題・画面の文言に使う日本語の文字が、すべてフォントに入っていること（足りない文字はシステム書体に化ける）。
    func testEveryJapaneseCharacterWeShipHasAGlyph() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appending(path: "NihonshuQuiz")
        var text = ""
        let fm = FileManager.default
        for case let url as URL in fm.enumerator(at: root, includingPropertiesForKeys: nil)! {
            if ["swift", "json"].contains(url.pathExtension), !url.path.contains("Fonts") {
                text += (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            }
        }
        let font = UIFont(name: "ShipporiMincho-Regular", size: 16)!
        var missing = Set<Character>()
        for ch in Set(text) where ch.unicodeScalars.allSatisfy({ $0.value >= 0x3000 && $0.value != 0x3000 }) {
            var glyph = [CGGlyph](repeating: 0, count: 2)
            var chars = Array(String(ch).utf16)
            if !CTFontGetGlyphsForCharacters(font, &chars, &glyph, chars.count) { missing.insert(ch) }
        }
        XCTAssertTrue(missing.isEmpty, "フォントにない文字: \(String(missing))")
    }
}

