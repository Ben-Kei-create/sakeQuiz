import Foundation

/// 文章の中の難しい言葉に、ふりがなを付ける。同じ言葉は、1つの文章の中で、最初の1回だけ。
struct RubyAnnotator {
    struct Segment: Equatable {
        let base: String
        let reading: String?
    }

    /// 言葉 → 読み。
    let dictionary: [String: String]
    private let wordsLongestFirst: [String]

    init(dictionary: [String: String]) {
        self.dictionary = dictionary
        wordsLongestFirst = dictionary.keys.sorted { ($0.count, $1) > ($1.count, $0) }
    }

    static func load(from bundle: Bundle = .main) -> RubyAnnotator {
        guard let url = bundle.url(forResource: "ruby", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let words = try? JSONDecoder().decode([String: String].self, from: data) else {
            return RubyAnnotator(dictionary: [:])
        }
        return RubyAnnotator(dictionary: words)
    }

    func segments(in text: String) -> [Segment] {
        guard !dictionary.isEmpty else { return [Segment(base: text, reading: nil)] }
        let chars = Array(text)
        var result: [Segment] = []
        var plain = ""
        var seen = Set<String>()
        var i = 0
        while i < chars.count {
            var matched: String?
            for word in wordsLongestFirst {
                let w = Array(word)
                if i + w.count <= chars.count, Array(chars[i..<i + w.count]) == w { matched = word; break }
            }
            if let word = matched, !seen.contains(word), let reading = dictionary[word] {
                if !plain.isEmpty { result.append(Segment(base: plain, reading: nil)); plain = "" }
                result.append(Segment(base: word, reading: reading))
                seen.insert(word)
                i += word.count
            } else if let word = matched {
                plain += word
                i += word.count
            } else {
                plain.append(chars[i])
                i += 1
            }
        }
        if !plain.isEmpty { result.append(Segment(base: plain, reading: nil)) }
        return result
    }

    /// 読み上げと音声読み上げ（VoiceOver）用。難しい言葉は、読みに置き換える（誤読を防ぐ）。
    func spokenText(for text: String) -> String {
        segments(in: text).map { $0.reading ?? $0.base }.joined()
    }
}
