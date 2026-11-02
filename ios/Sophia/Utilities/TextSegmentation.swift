import Foundation
import NaturalLanguage

/// Japanese is written without spaces. Every view that lays a sentence out word by word
/// (the course reader, the onboarding animations) used to cut it on spaces, so a whole
/// Japanese sentence became one block that cannot wrap and ran off the screen. These
/// helpers cut such text where a line may break instead. Text in a script that uses spaces
/// (Latin, Cyrillic, Greek…) is returned exactly as it was.
enum TextSegmentation {
    /// A line never ends on an opening bracket: it goes with the word that follows.
    private static let openingBrackets: Set<Character> = ["（", "「", "『", "【", "〈", "《", "［", "｛"]

    /// Kana and CJK ideographs, the characters that come without spaces around them.
    static func containsCJK(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            let value = scalar.value
            if (value >= 0x3040 && value <= 0x30FF) || (value >= 0x3400 && value <= 0x9FFF) {
                return true
            }
        }
        return false
    }

    /// The pieces of a run of text (no spaces in it) between which a line may break.
    /// Punctuation after a word stays with that word, so a line does not start with "、".
    static func breakableChunks(_ chunk: String) -> [String] {
        guard containsCJK(chunk) else { return [chunk] }

        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = chunk
        var starts: [String.Index] = []
        tokenizer.enumerateTokens(in: chunk.startIndex..<chunk.endIndex) { range, _ in
            starts.append(range.lowerBound)
            return true
        }
        // No break found (the tokenizer has nothing for this text): cut every few characters
        // rather than leave one block that cannot wrap.
        if starts.count <= 1 {
            starts = []
            var position = chunk.startIndex
            while position < chunk.endIndex {
                starts.append(position)
                position = chunk.index(position, offsetBy: 6, limitedBy: chunk.endIndex) ?? chunk.endIndex
            }
        }
        guard starts.count > 1 else { return [chunk] }
        starts[0] = chunk.startIndex

        var pieces: [String] = []
        for index in 0..<starts.count {
            let end = index + 1 < starts.count ? starts[index + 1] : chunk.endIndex
            pieces.append(String(chunk[starts[index]..<end]))
        }

        var result: [String] = []
        var carry = ""
        for index in 0..<pieces.count {
            var piece = carry + pieces[index]
            carry = ""
            if index < pieces.count - 1 {
                while piece.count > 1, let last = piece.last, openingBrackets.contains(last) {
                    carry = String(last) + carry
                    piece.removeLast()
                }
            }
            result.append(piece)
        }
        return result
    }

    /// The words of an animated sentence. Spaces cut it first, then each run of Japanese
    /// text is cut where a line may break. `keepLastWhole` leaves the last run in one piece:
    /// the "Transforme ce temps" screen swaps its last word for a rotating list.
    static func animationWords(_ text: String, keepLastWhole: Bool = false) -> [String] {
        let chunks = text.split(separator: " ").map(String.init)
        var words: [String] = []
        for index in 0..<chunks.count {
            if keepLastWhole && index == chunks.count - 1 {
                words.append(chunks[index])
            } else {
                words.append(contentsOf: breakableChunks(chunks[index]))
            }
        }
        return words
    }
}
