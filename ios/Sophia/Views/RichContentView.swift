import SwiftUI

/// Renders course lesson content with inline rich blocks:
/// - `[image description]`   → inline image (looked up in CourseImages asset catalog by slug)
/// - `{fun fact}`             → highlighted fun-fact card
/// - `||à retenir||`          → key takeaway card
/// Markdown bold (`**text**`) is preserved in text blocks.
struct RichContentView: View {
    let content: String
    let accent: Color

    static let ink = Color.black

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: ContentBlock) -> some View {
        switch block {
        case .text(let str):
            Text(markdown(str))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Self.ink)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        case .image(let name):
            CourseInlineImage(rawName: name)
        case .funFact(let str):
            FunFactBox(text: str)
        case .highlight(let str):
            HighlightBox(text: str, accent: accent)
        }
    }

    private var blocks: [ContentBlock] {
        Self.parse(content)
    }

    private func markdown(_ s: String) -> AttributedString {
        let cleaned = s.replacingOccurrences(of: "\\n", with: "\n")
        if let a = try? AttributedString(markdown: cleaned, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return a
        }
        return AttributedString(cleaned)
    }

    nonisolated enum ContentBlock {
        case text(String)
        case image(String)
        case funFact(String)
        case highlight(String)
    }

    /// Parses raw content into ordered blocks.
    /// Tokens: `[...]` image, `{...}` fun fact, `||...||` highlight.
    nonisolated static func parse(_ raw: String) -> [ContentBlock] {
        let normalized = raw.replacingOccurrences(of: "\\n", with: "\n")
        var blocks: [ContentBlock] = []
        var buffer = ""

        func flushText() {
            let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                blocks.append(.text(trimmed))
            }
            buffer = ""
        }

        let chars = Array(normalized)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            // Highlight ||...||
            if c == "|" && i + 1 < chars.count && chars[i + 1] == "|" {
                if let end = findClose(chars, start: i + 2, close: "||") {
                    flushText()
                    let inner = String(chars[(i + 2)..<end])
                    blocks.append(.highlight(inner.trimmingCharacters(in: .whitespacesAndNewlines)))
                    i = end + 2
                    continue
                }
            }
            // Fun fact {...}
            if c == "{" {
                if let end = indexOf(chars, char: "}", from: i + 1) {
                    flushText()
                    let inner = String(chars[(i + 1)..<end])
                    blocks.append(.funFact(inner.trimmingCharacters(in: .whitespacesAndNewlines)))
                    i = end + 1
                    continue
                }
            }
            // Image [...]
            if c == "[" {
                if let end = indexOf(chars, char: "]", from: i + 1) {
                    let inner = String(chars[(i + 1)..<end])
                    // Avoid markdown-link false positives: must not look like a URL bracket
                    if !inner.contains("\n") && inner.count < 200 {
                        flushText()
                        blocks.append(.image(inner.trimmingCharacters(in: .whitespacesAndNewlines)))
                        i = end + 1
                        continue
                    }
                }
            }
            buffer.append(c)
            i += 1
        }
        flushText()
        return blocks
    }

    nonisolated private static func indexOf(_ chars: [Character], char: Character, from: Int) -> Int? {
        var i = from
        while i < chars.count {
            if chars[i] == char { return i }
            i += 1
        }
        return nil
    }

    nonisolated private static func findClose(_ chars: [Character], start: Int, close: String) -> Int? {
        let target = Array(close)
        var i = start
        while i <= chars.count - target.count {
            var match = true
            for k in 0..<target.count {
                if chars[i + k] != target[k] { match = false; break }
            }
            if match { return i }
            i += 1
        }
        return nil
    }
}

/// Inline image loaded from `CourseImages/` asset catalog.
/// The image name is derived from the bracketed description (slug).
struct CourseInlineImage: View {
    let rawName: String

    private var assetName: String { Self.slug(rawName) }
    private var credit: ImageCredit? { ImageCreditStore.shared.credit(for: assetName) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if let ui = Self.loadImage(named: assetName) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    placeholder
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipShape(.rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.black, lineWidth: 2.5)
            }

            if let credit, !credit.formatted.isEmpty {
                Text(credit.formatted)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.black.opacity(0.4))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.white
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.black.opacity(0.4))
                Text(rawName)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
        }
    }

    /// Tries asset catalog first, then bundle resources (jpg/png/jpeg).
    /// Loose files inside synchronized folder groups are not auto-indexed by
    /// `UIImage(named:)` without extension, so we look them up explicitly.
    static func loadImage(named name: String) -> UIImage? {
        if let ui = UIImage(named: name) { return ui }
        let bundle = Bundle.main
        for ext in ["jpg", "jpeg", "png", "JPG", "PNG"] {
            if let url = bundle.url(forResource: name, withExtension: ext),
               let data = try? Data(contentsOf: url),
               let ui = UIImage(data: data) {
                return ui
            }
            if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "CourseImages"),
               let data = try? Data(contentsOf: url),
               let ui = UIImage(data: data) {
                return ui
            }
        }
        return nil
    }

    nonisolated static func slug(_ s: String) -> String {
        let folded = s.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
        var out = ""
        var prevUnderscore = false
        for scalar in folded.unicodeScalars {
            if allowed.contains(scalar) {
                out.append(Character(scalar))
                prevUnderscore = false
            } else if !prevUnderscore {
                out.append("_")
                prevUnderscore = true
            }
        }
        return out.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }
}

/// "Le saviez-vous ?" card — neobrutalism style with cyan pill badge.
struct FunFactBox: View {
    let text: String

    private let mint = Color(red: 0.553, green: 0.953, blue: 0.953)

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(markdown(text))
                .font(.system(.body, design: .rounded, weight: .bold))
                .italic()
                .foregroundStyle(.black)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 36)
                .padding(.bottom, 22)
                .background {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white)
                        .overlay {
                            RoundedRectangle(cornerRadius: 22)
                                .strokeBorder(.black, lineWidth: 3)
                        }
                }
                .padding(.top, 18)

            HStack(spacing: 6) {
                Text("🧠").font(.system(size: 14))
                Text("LE SAVIEZ-VOUS ?")
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .foregroundStyle(.black)
                    .tracking(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(mint)
                    .overlay { Capsule().strokeBorder(.black, lineWidth: 2.5) }
            }
            .padding(.leading, 16)
        }
        .shadow(color: .black.opacity(0.9), radius: 0, x: 0, y: 4)
    }

    private func markdown(_ s: String) -> AttributedString {
        if let a = try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return a
        }
        return AttributedString(s)
    }
}

/// "À retenir" key takeaway card — neobrutalism style with pink badge.
struct HighlightBox: View {
    let text: String
    let accent: Color

    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(markdown(text))
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(.black)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 36)
                .padding(.bottom, 22)
                .background {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white)
                        .overlay {
                            RoundedRectangle(cornerRadius: 22)
                                .strokeBorder(.black, lineWidth: 3)
                        }
                }
                .padding(.top, 18)

            HStack(spacing: 6) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black)
                Text("À RETENIR")
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .foregroundStyle(.black)
                    .tracking(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(pink)
                    .overlay { Capsule().strokeBorder(.black, lineWidth: 2.5) }
            }
            .padding(.leading, 16)
        }
        .shadow(color: .black.opacity(0.9), radius: 0, x: 0, y: 4)
    }

    private func markdown(_ s: String) -> AttributedString {
        if let a = try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return a
        }
        return AttributedString(s)
    }
}
