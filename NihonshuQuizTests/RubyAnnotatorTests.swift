import XCTest
@testable import NihonshuQuiz

final class RubyAnnotatorTests: XCTestCase {
    private let annotator = RubyAnnotator(dictionary: ["麹": "こうじ", "麹米": "こうじまい", "酛": "もと", "精米歩合": "せいまいぶあい", "歩合": "ぶあい"])

    func testLongestWordWinsAndOnlyTheFirstOccurrenceGetsReading() {
        let segments = annotator.segments(in: "麹米と麹。麹米。")
        XCTAssertEqual(segments.filter { $0.reading != nil }.map(\.base), ["麹米", "麹"], "麹米の2回目には、付けない")
        XCTAssertEqual(segments.map(\.base).joined(), "麹米と麹。麹米。", "文字は、変わらない")
    }

    func testTextWithoutHardWordsIsUntouched() {
        XCTAssertEqual(annotator.segments(in: "水を飲む。"), [.init(base: "水を飲む。", reading: nil)])
        XCTAssertEqual(annotator.segments(in: ""), [])
    }

    func testOverlappingWordsDoNotDoubleAnnotate() {
        let segments = annotator.segments(in: "精米歩合と歩合")
        XCTAssertEqual(segments.compactMap(\.reading), ["せいまいぶあい", "ぶあい"])
    }

    func testSpokenTextReplacesHardWordsWithTheirReading() {
        XCTAssertEqual(annotator.spokenText(for: "酛を造る"), "もとを造る")
    }

    func testEmptyDictionaryReturnsTextAsIs() {
        XCTAssertEqual(RubyAnnotator(dictionary: [:]).segments(in: "麹"), [.init(base: "麹", reading: nil)])
    }

    func testBundledDictionaryHasNoEmptyReadingsAndCoversKeyWords() {
        let bundled = RubyAnnotator.load(from: Bundle(for: ProgressStore.self))
        XCTAssertTrue(bundled.dictionary.values.allSatisfy { !$0.isEmpty })
        for word in ["麹", "酛", "杜氏", "灘", "宮水"] { XCTAssertNotNil(bundled.dictionary[word], word) }
    }
}
