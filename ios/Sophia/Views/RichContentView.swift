import SwiftUI

/// Renders course lesson content with inline rich blocks:
/// - `[image description]`   → inline image (looked up in CourseImages asset catalog by slug)
/// - `{fun fact}`             → highlighted fun-fact card
/// - `||à retenir||`          → key takeaway card
/// - `<terme>`                → inline glossary term (pastel highlight + bottom sheet)
/// Markdown bold (`**text**`) is preserved in text blocks.
struct RichContentView: View {
    let content: String
    let accent: Color
    let courseTitle: String

    @State private var selectedGlossaryEntry: GlossaryEntry?

    static let ink = Color.black
    fileprivate static let bodyFont = Font.system(.title3, design: .rounded)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .sheet(item: $selectedGlossaryEntry) { entry in
            GlossaryTermSheet(entry: entry)
        }
    }

    @ViewBuilder
    private func blockView(_ block: ContentBlock) -> some View {
        switch block {
        case .text(let str):
            CourseInlineText(
                raw: str,
                courseTitle: courseTitle,
                onGlossaryTap: { selectedGlossaryEntry = $0 }
            )
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

    nonisolated enum ContentBlock {
        case text(String)
        case image(String)
        case funFact(String)
        case highlight(String)
    }

    /// Parses raw content into ordered blocks.
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
            if c == "|" && i + 1 < chars.count && chars[i + 1] == "|" {
                if let end = findClose(chars, start: i + 2, close: "||") {
                    flushText()
                    let inner = String(chars[(i + 2)..<end])
                    blocks.append(.highlight(inner.trimmingCharacters(in: .whitespacesAndNewlines)))
                    i = end + 2
                    continue
                }
            }
            if c == "{" {
                if let end = indexOf(chars, char: "}", from: i + 1) {
                    flushText()
                    let inner = String(chars[(i + 1)..<end])
                    blocks.append(.funFact(inner.trimmingCharacters(in: .whitespacesAndNewlines)))
                    i = end + 1
                    continue
                }
            }
            if c == "[" {
                if let end = indexOf(chars, char: "]", from: i + 1) {
                    let inner = String(chars[(i + 1)..<end])
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

    nonisolated static func tokenizeInline(_ raw: String) -> [InlineRun] {
        let normalized = raw.replacingOccurrences(of: "\\n", with: "\n")
        var runs: [InlineRun] = []
        var index = normalized.startIndex
        var bold = false
        var textBuffer = ""

        func flushTextBuffer() {
            guard !textBuffer.isEmpty else { return }
            let cleaned = textBuffer.replacingOccurrences(of: "**", with: "")
            guard !cleaned.isEmpty else {
                textBuffer = ""
                return
            }
            runs.append(InlineRun(kind: .text, content: cleaned, bold: bold))
            textBuffer = ""
        }

        while index < normalized.endIndex {
            if normalized[index...].hasPrefix("**") {
                flushTextBuffer()
                bold.toggle()
                index = normalized.index(index, offsetBy: 2)
                continue
            }

            if normalized[index] == "<" {
                if let close = normalized[index...].firstIndex(of: ">") {
                    flushTextBuffer()
                    let start = normalized.index(after: index)
                    let term = String(normalized[start..<close]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !term.isEmpty {
                        runs.append(InlineRun(kind: .glossary, content: term, bold: bold))
                    }
                    index = normalized.index(after: close)
                    continue
                }
            }

            textBuffer.append(normalized[index])
            index = normalized.index(after: index)
        }

        flushTextBuffer()
        return runs
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

struct InlineRun: Hashable {
    enum Kind: Hashable { case text, glossary }
    let kind: Kind
    let content: String
    let bold: Bool
}

private struct FlowGlossaryTokenKey: LayoutValueKey {
    static let defaultValue = false
}

private struct FlowProseTokenKey: LayoutValueKey {
    static let defaultValue = false
}

private extension View {
    func flowGlossaryToken() -> some View {
        layoutValue(key: FlowGlossaryTokenKey.self, value: true)
    }

    func flowProseToken() -> some View {
        layoutValue(key: FlowProseTokenKey.self, value: true)
    }
}

private struct CourseInlineText: View {
    let raw: String
    let courseTitle: String
    let onGlossaryTap: (GlossaryEntry) -> Void

    private var paragraphs: [ParagraphContent] {
        Self.buildParagraphContent(from: raw, courseTitle: courseTitle)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(paragraph.lines.enumerated()), id: \.offset) { _, line in
                        FlowInlineLayout(spacing: 0, rowSpacing: 10) {
                            ForEach(Array(line.enumerated()), id: \.offset) { _, token in
                                switch token {
                                case .prose(let text, let bold):
                                    Text(verbatim: text)
                                        .font(RichContentView.bodyFont)
                                        .fontWeight(bold ? .semibold : .regular)
                                        .foregroundStyle(RichContentView.ink.opacity(bold ? 1.0 : 0.9))
                                        .flowProseToken()
                                case .glossary(let term, let bold, let entry):
                                    ShinyGlossaryPill(term: term, bold: bold, pastel: entry.classification.pastel) {
                                        onGlossaryTap(entry)
                                    }
                                    .flowGlossaryToken()
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private struct ParagraphContent {
        var lines: [[FlowToken]]
    }

    private enum FlowToken {
        case prose(String, bold: Bool)
        case glossary(String, bold: Bool, entry: GlossaryEntry)
    }

    private static func buildParagraphContent(from raw: String, courseTitle: String) -> [ParagraphContent] {
        let normalized = raw.replacingOccurrences(of: "\\n", with: "\n")
        return normalized
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { paragraph in
                let lines = paragraph
                    .components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .map { line in
                        buildFlowTokens(from: RichContentView.tokenizeInline(line), courseTitle: courseTitle)
                    }
                return ParagraphContent(lines: lines)
            }
    }

    private static func buildFlowTokens(from runs: [InlineRun], courseTitle: String) -> [FlowToken] {
        var tokens: [FlowToken] = []

        for run in runs {
            switch run.kind {
            case .glossary:
                if let entry = GlossaryStore.entry(courseTitle: courseTitle, displayTerm: run.content) {
                    tokens.append(.glossary(run.content, bold: run.bold, entry: entry))
                } else {
                    tokens.append(contentsOf: proseTokens(from: run.content, bold: run.bold))
                }
            case .text:
                tokens.append(contentsOf: proseTokens(from: run.content, bold: run.bold))
            }
        }
        return tokens
    }

    /// Splits prose into whitespace + word tokens so glossary pills flow inline with the sentence.
    private static func proseTokens(from text: String, bold: Bool) -> [FlowToken] {
        guard !text.isEmpty else { return [] }
        var tokens: [FlowToken] = []
        var index = text.startIndex

        while index < text.endIndex {
            if text[index].isWhitespace {
                var whitespace = ""
                while index < text.endIndex, text[index].isWhitespace {
                    whitespace.append(text[index])
                    index = text.index(after: index)
                }
                tokens.append(.prose(whitespace, bold: bold))
                continue
            }

            var chunk = ""
            while index < text.endIndex, !text[index].isWhitespace {
                chunk.append(text[index])
                index = text.index(after: index)
            }
            tokens.append(.prose(chunk, bold: bold))
        }
        return tokens
    }
}

private struct ShinyGlossaryPill: View {
    let term: String
    let bold: Bool
    let pastel: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(term)
                .font(RichContentView.bodyFont)
                .fontWeight(bold ? .semibold : .medium)
                .foregroundStyle(RichContentView.ink)
                .padding(.horizontal, 8)
                .padding(.top, 1)
                .padding(.bottom, 2)
                .background {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [pastel.opacity(0.98), pastel.opacity(0.72)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(pastel.opacity(0.95), lineWidth: 1)
                        }
                        .overlay {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.55), .white.opacity(0.05), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                }
        }
        .buttonStyle(.plain)
        .alignmentGuide(.firstTextBaseline) { dimensions in
            dimensions[.firstTextBaseline] + 2
        }
    }
}

/// Places words and glossary pills left-to-right, wrapping at the container width.
private struct FlowInlineLayout: Layout {
    var spacing: CGFloat
    var rowSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)

        var rows: [CGFloat: [Int]] = [:]
        for (index, frame) in result.frames.enumerated() {
            rows[frame.minY, default: []].append(index)
        }

        for (_, indices) in rows {
            var rowBaseline: CGFloat = 0
            var baselines: [Int: CGFloat] = [:]

            for index in indices {
                let frame = result.frames[index]
                let dimensions = subviews[index].dimensions(in: ProposedViewSize(frame.size))
                let baseline = dimensions[.firstTextBaseline]
                baselines[index] = baseline
                rowBaseline = max(rowBaseline, baseline)
            }

            for index in indices {
                let frame = result.frames[index]
                let baseline = baselines[index] ?? frame.height
                let yAdjust = rowBaseline - baseline
                subviews[index].place(
                    at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY + yAdjust),
                    proposal: ProposedViewSize(frame.size)
                )
            }
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        guard maxWidth.isFinite, maxWidth > 0 else {
            return (CGSize(width: 0, height: 0), subviews.map { _ in .zero })
        }

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for index in subviews.indices {
            let subview = subviews[index]
            let size = subview.sizeThatFits(.unspecified)
            let isGlossary = subview[FlowGlossaryTokenKey.self]
            let isProse = subview[FlowProseTokenKey.self]

            if isProse, isFollowedByGlossary(at: index, subviews: subviews) {
                let groupWidth = widthThroughNextGlossary(from: index, subviews: subviews, spacing: spacing)
                if x > 0, x + groupWidth > maxWidth + 0.5 {
                    x = 0
                    y += rowHeight + rowSpacing
                    rowHeight = 0
                }
            }

            if x > 0, x + size.width > maxWidth + 0.5 {
                if isGlossary, let wordIndex = proseWordBeforeGlossary(
                    at: index,
                    subviews: subviews,
                    frames: frames,
                    rowY: y
                ), frames[wordIndex].minX > 0.5 {
                    let oldRowHeight = frames[..<wordIndex].map(\.height).max() ?? rowHeight
                    x = 0
                    y += oldRowHeight + rowSpacing
                    let newRowY = y
                    rowHeight = 0
                    x = 0

                    for moveIndex in wordIndex..<index {
                        let moving = frames[moveIndex]
                        frames[moveIndex] = CGRect(
                            x: x,
                            y: newRowY,
                            width: moving.width,
                            height: moving.height
                        )
                        rowHeight = max(rowHeight, moving.height)
                        x += moving.width + spacing
                    }
                } else {
                    x = 0
                    y += rowHeight + rowSpacing
                    rowHeight = 0
                }
            }

            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing

            if x > maxWidth + 0.5 {
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }

    private func proseWordBeforeGlossary(
        at index: Int,
        subviews: Subviews,
        frames: [CGRect],
        rowY: CGFloat
    ) -> Int? {
        guard index > 0 else { return nil }

        var candidate = index - 1
        if candidate >= 0,
           subviews[candidate][FlowProseTokenKey.self],
           frames[candidate].width < 6,
           candidate > 0 {
            candidate -= 1
        }

        guard candidate >= 0,
              subviews[candidate][FlowProseTokenKey.self],
              frames[candidate].minY == rowY,
              frames[candidate].width >= 6 else {
            return nil
        }
        return candidate
    }

    private func isFollowedByGlossary(at index: Int, subviews: Subviews) -> Bool {
        var lookahead = index + 1
        while lookahead < subviews.count {
            if subviews[lookahead][FlowGlossaryTokenKey.self] { return true }
            if subviews[lookahead][FlowProseTokenKey.self],
               subviews[lookahead].sizeThatFits(.unspecified).width >= 6 {
                return false
            }
            lookahead += 1
        }
        return false
    }

    private func widthThroughNextGlossary(from index: Int, subviews: Subviews, spacing: CGFloat) -> CGFloat {
        var width: CGFloat = 0
        var lookahead = index
        while lookahead < subviews.count {
            let size = subviews[lookahead].sizeThatFits(.unspecified)
            width += size.width
            if lookahead > index { width += spacing }
            if subviews[lookahead][FlowGlossaryTokenKey.self] { break }
            lookahead += 1
        }
        return width
    }
}

private struct FullscreenImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
    let credit: String?
}

/// Inline image loaded from `CourseImages/` asset catalog.
struct CourseInlineImage: View {
    let rawName: String

    @State private var fullscreenItem: FullscreenImageItem?

    private var assetName: String { Self.slug(rawName) }
    private var credit: ImageCredit? { ImageCreditStore.shared.credit(for: assetName) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if let ui = Self.loadImage(named: assetName) {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .overlay {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            fullscreenItem = FullscreenImageItem(
                                image: ui,
                                credit: credit?.formatted
                            )
                        }
                } else {
                    placeholder
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                }
            }
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .fullScreenCover(item: $fullscreenItem) { item in
            CourseImageFullscreenView(image: item.image, credit: item.credit)
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
            SimpleBoldText(raw: text, font: .system(.body, design: .rounded), italic: true)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 36)
                .padding(.bottom, 22)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.black)
                            .offset(y: 4)
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white)
                            .overlay {
                                RoundedRectangle(cornerRadius: 22)
                                    .strokeBorder(.black, lineWidth: 3)
                            }
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, 4)

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
    }
}

/// "À retenir" key takeaway card — neobrutalism style with pink badge.
struct HighlightBox: View {
    let text: String
    let accent: Color

    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)

    var body: some View {
        ZStack(alignment: .topLeading) {
            SimpleBoldText(raw: text, font: .system(.body, design: .rounded), baseWeight: .semibold)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 36)
                .padding(.bottom, 22)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.black)
                            .offset(y: 4)
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white)
                            .overlay {
                                RoundedRectangle(cornerRadius: 22)
                                    .strokeBorder(.black, lineWidth: 3)
                            }
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, 4)

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
    }
}

private struct SimpleBoldText: View {
    let raw: String
    var font: Font = RichContentView.bodyFont
    var italic: Bool = false
    var baseWeight: Font.Weight = .regular

    private var runs: [InlineRun] {
        RichContentView.tokenizeInline(raw).filter { $0.kind == .text }
    }

    var body: some View {
        composedText
            .font(font)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var composedText: Text {
        let textRuns = runs
        guard let first = textRuns.first else { return Text(verbatim: "") }
        return textRuns.dropFirst().reduce(textSegment(for: first)) { partial, run in
            partial + textSegment(for: run)
        }
    }

    private func textSegment(for run: InlineRun) -> Text {
        Text(verbatim: run.content)
            .fontWeight(run.bold ? .semibold : baseWeight)
            .italic(italic)
            .foregroundColor(RichContentView.ink.opacity(run.bold ? 1.0 : 0.9))
    }
}
