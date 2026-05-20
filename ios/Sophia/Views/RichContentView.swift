import SwiftUI

/// Renders course lesson content with inline rich blocks:
/// - `[image description]`   → inline image (looked up in CourseImages asset catalog by slug)
/// - `{fun fact}`             → highlighted fun-fact card
/// - `||à retenir||`          → key takeaway card
/// Markdown bold (`**text**`) is preserved in text blocks.
struct RichContentView: View {
    let content: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(6)
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

    var body: some View {
        Group {
            if let ui = UIImage(named: assetName) {
                Image(uiImage: ui)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .clipShape(.rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.06), lineWidth: 1)
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.35))
                Text(rawName)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
        }
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

/// "Le saviez-vous ?" card.
struct FunFactBox: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(red: 0.99, green: 0.78, blue: 0.30))
                .frame(width: 28, height: 28)
                .background(Color(red: 0.99, green: 0.78, blue: 0.30).opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("Le saviez-vous ?")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(Color(red: 0.99, green: 0.78, blue: 0.30))
                    .textCase(.uppercase)
                    .tracking(0.6)
                Text(markdown(text))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.99, green: 0.78, blue: 0.30).opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(red: 0.99, green: 0.78, blue: 0.30).opacity(0.25), lineWidth: 1)
                }
        }
    }

    private func markdown(_ s: String) -> AttributedString {
        if let a = try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return a
        }
        return AttributedString(s)
    }
}

/// "À retenir" key takeaway card.
struct HighlightBox: View {
    let text: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)
                .background(accent.opacity(0.18), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("À retenir")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(accent)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Text(markdown(text))
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.white)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(accent.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(accent.opacity(0.35), lineWidth: 1)
                }
        }
    }

    private func markdown(_ s: String) -> AttributedString {
        if let a = try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return a
        }
        return AttributedString(s)
    }
}
