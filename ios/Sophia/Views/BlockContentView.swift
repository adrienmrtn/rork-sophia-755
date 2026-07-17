import SwiftUI
import UIKit

/// Renders a structured ("v2") course section: hero, key dates, and typed blocks.
///
/// Prose is rendered through a native `UITextView` (see `ProseTextView`) for reliable
/// wrapping, justification, restyled highlights, and tappable glossary terms — replacing
/// the fragile hand-rolled `FlowInlineLayout` used by the legacy `RichContentView`.
struct BlockContentView: View {
    let content: CourseContentV2
    let section: CourseSectionV2
    let isFirst: Bool
    let accent: Color
    let courseId: String
    let courseTitle: String

    @State private var selectedGlossaryEntry: GlossaryEntry?

    private static let ink = Color.black

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: $selectedGlossaryEntry) { entry in
            GlossaryTermSheet(entry: entry)
        }
    }

    @ViewBuilder
    private var header: some View {
        if isFirst, let hero = content.hero {
            HeroBlockView(
                hero: hero,
                title: content.title,
                subtitle: content.subtitle,
                accent: accent
            )
        } else {
            Text(section.title)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(Self.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func blockView(_ block: ContentBlockV2) -> some View {
        switch block {
        case .heading(let text):
            Text(text)
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(Self.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

        case .paragraph(let text):
            ProseParagraph(
                raw: text,
                accent: accent,
                courseId: courseId,
                courseTitle: courseTitle,
                onGlossaryTap: { selectedGlossaryEntry = $0 }
            )

        case .image(let image):
            AspectImageView(block: image)

        case .timeline(let events):
            TimelineBlockView(events: events, accent: accent)

        case .funFact(let text):
            FunFactCardV2(
                raw: text,
                courseId: courseId,
                courseTitle: courseTitle,
                accent: accent,
                onGlossaryTap: { selectedGlossaryEntry = $0 }
            )

        case .takeaway(let text):
            TakeawayCardV2(
                raw: text,
                courseId: courseId,
                courseTitle: courseTitle,
                accent: accent,
                onGlossaryTap: { selectedGlossaryEntry = $0 }
            )

        case .quote(let text, let attribution):
            QuoteBlockView(text: text, attribution: attribution, accent: accent)
        }
    }
}

// MARK: - Prose (native attributed text)

/// A justified prose paragraph with restyled highlights and tappable glossary links.
struct ProseParagraph: View {
    let raw: String
    let accent: Color
    let courseId: String
    let courseTitle: String
    let onGlossaryTap: (GlossaryEntry) -> Void

    var body: some View {
        ProseTextView(
            attributed: InlineAttributedBuilder.build(
                raw: raw,
                courseId: courseId,
                courseTitle: courseTitle,
                accent: UIColor(accent)
            ),
            linkUnderlineColor: UIColor(accent),
            onGlossaryTap: onGlossaryTap
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Builds an `NSAttributedString` from Sophia inline markup:
/// `**bold**`, `==highlight==` (marker), `[[Term]]` (tappable glossary).
enum InlineAttributedBuilder {
    /// Custom attribute carrying a glossary URL. We deliberately avoid `.link` so
    /// UITextView doesn't force a blue tint or a tap-time selection shift; the tap
    /// gesture reads this key directly instead.
    static let glossaryURLKey = NSAttributedString.Key("SophiaGlossaryURL")

    static func build(
        raw: String,
        courseId: String,
        courseTitle: String,
        accent: UIColor,
        italic: Bool = false,
        baseBold: Bool = false,
        alignment: NSTextAlignment = .justified
    ) -> NSAttributedString {
        let normalized = raw.replacingOccurrences(of: "\\n", with: "\n")
        let chars = Array(normalized)
        let result = NSMutableAttributedString()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineSpacing = 5
        paragraphStyle.hyphenationFactor = 1
        paragraphStyle.lineBreakMode = .byWordWrapping

        var bold = baseBold
        var highlight = false
        var buffer = ""

        func flush() {
            guard !buffer.isEmpty else { return }
            result.append(
                NSAttributedString(
                    string: buffer,
                    attributes: textAttributes(
                        bold: bold,
                        highlight: highlight,
                        italic: italic,
                        paragraphStyle: paragraphStyle
                    )
                )
            )
            buffer = ""
        }

        var i = 0
        while i < chars.count {
            if matches(chars, at: i, token: "**") {
                flush()
                bold.toggle()
                i += 2
                continue
            }
            if matches(chars, at: i, token: "==") {
                flush()
                highlight.toggle()
                i += 2
                continue
            }
            if matches(chars, at: i, token: "[[") {
                if let end = findToken(chars, from: i + 2, token: "]]") {
                    flush()
                    let term = String(chars[(i + 2)..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
                    appendGlossary(
                        term: term,
                        into: result,
                        bold: bold,
                        italic: italic,
                        accent: accent,
                        paragraphStyle: paragraphStyle,
                        courseId: courseId,
                        courseTitle: courseTitle
                    )
                    i = end + 2
                    continue
                }
            }
            buffer.append(chars[i])
            i += 1
        }
        flush()
        return result
    }

    private static func appendGlossary(
        term: String,
        into result: NSMutableAttributedString,
        bold: Bool,
        italic: Bool,
        accent: UIColor,
        paragraphStyle: NSParagraphStyle,
        courseId: String,
        courseTitle: String
    ) {
        guard !term.isEmpty else { return }

        var attributes = textAttributes(
            bold: bold,
            highlight: false,
            italic: italic,
            paragraphStyle: paragraphStyle
        )

        if GlossaryStore.entry(courseId: courseId, courseTitle: courseTitle, displayTerm: term) != nil,
           let url = GlossaryStore.linkURL(courseId: courseId, courseTitle: courseTitle, displayTerm: term) {
            attributes[glossaryURLKey] = url
            attributes[.underlineStyle] = NSUnderlineStyle.thick.rawValue
            attributes[.underlineColor] = accent
            attributes[.foregroundColor] = UIColor.label
        }
        result.append(NSAttributedString(string: term, attributes: attributes))
    }

    private static func textAttributes(
        bold: Bool,
        highlight: Bool,
        italic: Bool,
        paragraphStyle: NSParagraphStyle
    ) -> [NSAttributedString.Key: Any] {
        _ = highlight // marker highlight deprecated: markers are stripped, no visual style.
        let attributes: [NSAttributedString.Key: Any] = [
            .font: roundedFont(bold: bold, italic: italic),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: bold
                ? UIColor.label
                : UIColor.label.withAlphaComponent(0.9),
        ]
        return attributes
    }

    private static func roundedFont(bold: Bool, italic: Bool) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: .body)
        var descriptor = base.fontDescriptor
        if let rounded = descriptor.withDesign(.rounded) {
            descriptor = rounded
        }
        var traits: UIFontDescriptor.SymbolicTraits = []
        if bold { traits.insert(.traitBold) }
        if italic { traits.insert(.traitItalic) }
        if !traits.isEmpty, let withTraits = descriptor.withSymbolicTraits(traits) {
            descriptor = withTraits
        }
        return UIFont(descriptor: descriptor, size: base.pointSize)
    }

    private static func matches(_ chars: [Character], at index: Int, token: String) -> Bool {
        let target = Array(token)
        guard index + target.count <= chars.count else { return false }
        for k in 0..<target.count where chars[index + k] != target[k] {
            return false
        }
        return true
    }

    private static func findToken(_ chars: [Character], from: Int, token: String) -> Int? {
        var i = from
        while i < chars.count {
            if matches(chars, at: i, token: token) { return i }
            i += 1
        }
        return nil
    }
}

/// A non-scrolling `UITextView` that self-sizes to its content width in SwiftUI.
struct ProseTextView: UIViewRepresentable {
    let attributed: NSAttributedString
    let linkUnderlineColor: UIColor
    let onGlossaryTap: (GlossaryEntry) -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        // Disable text selection so glossary taps fire instantly, without waiting on
        // UITextView's built-in selection/long-press disambiguation (the source of the
        // perceived latency). A custom tap recognizer handles link taps directly.
        textView.isSelectable = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = []

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.cancelsTouchesInView = false
        textView.addGestureRecognizer(tap)

        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.required, for: .vertical)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.onGlossaryTap = onGlossaryTap
        // Only rewrite the text when it actually changed. Re-assigning an identical
        // NSAttributedString forces a re-layout that visually nudges the paragraph when
        // unrelated state changes (e.g. presenting the glossary sheet on tap).
        if uiView.attributedText != attributed {
            uiView.attributedText = attributed
            uiView.invalidateIntrinsicContentSize()
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? (UIScreen.main.bounds.width - 48)
        let target = CGSize(width: width, height: .greatestFiniteMagnitude)
        let fitted = uiView.sizeThatFits(target)
        return CGSize(width: width, height: ceil(fitted.height))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onGlossaryTap: onGlossaryTap)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onGlossaryTap: (GlossaryEntry) -> Void

        init(onGlossaryTap: @escaping (GlossaryEntry) -> Void) {
            self.onGlossaryTap = onGlossaryTap
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = gesture.view as? UITextView else { return }
            let layoutManager = textView.layoutManager
            var location = gesture.location(in: textView)
            location.x -= textView.textContainerInset.left
            location.y -= textView.textContainerInset.top

            let glyphIndex = layoutManager.glyphIndex(for: location, in: textView.textContainer)
            // Ensure the tap actually landed on a glyph (not empty trailing space).
            let glyphRect = layoutManager.boundingRect(
                forGlyphRange: NSRange(location: glyphIndex, length: 1),
                in: textView.textContainer
            )
            guard glyphRect.contains(location) else { return }

            let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            guard charIndex < textView.textStorage.length else { return }

            if let url = textView.textStorage.attribute(
                InlineAttributedBuilder.glossaryURLKey, at: charIndex, effectiveRange: nil
            ) as? URL, let entry = GlossaryStore.entry(from: url) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onGlossaryTap(entry)
            }
        }
    }
}

// MARK: - Hero

private struct HeroBlockView: View {
    let hero: CourseHeroV2
    let title: String
    let subtitle: String?
    let accent: Color

    private let ink = Color.black

    private var ratio: CGFloat {
        AspectRatioSpec.value(from: hero.ratio) ?? (16.0 / 9.0)
    }

    private var image: UIImage? {
        CourseInlineImage.loadImage(named: CourseInlineImage.slug(hero.image))
    }

    private var creditText: String? {
        if let credit = hero.credit, !credit.isEmpty { return credit }
        let slug = CourseInlineImage.slug(hero.image)
        return ImageCreditStore.shared.credit(for: slug)?.formatted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Group {
                if let image {
                    Color.clear
                        .aspectRatio(ratio, contentMode: .fit)
                        .overlay {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                } else {
                    Color.clear
                        .aspectRatio(ratio, contentMode: .fit)
                        .overlay { ImagePlaceholder(label: hero.image) }
                }
            }
            .frame(maxWidth: .infinity)
            .clipShape(.rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(ink, lineWidth: 3)
            }

            if let creditText, !creditText.isEmpty {
                Text(creditText)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(ink.opacity(0.4))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }

            VStack(alignment: .leading, spacing: 8) {
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle.uppercased())
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                        .tracking(0.8)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(accent, in: Capsule())
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                }

                Text(title)
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)

                if let hook = hero.hook, !hook.isEmpty {
                    Text(hook)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Image block

/// Inline image that respects its real aspect ratio (no forced crop) with caption + credit.
struct AspectImageView: View {
    let block: ImageBlockV2

    @State private var fullscreenItem: FullscreenCourseImage?

    private let ink = Color.black

    private var slug: String { CourseInlineImage.slug(block.asset) }
    private var image: UIImage? { CourseInlineImage.loadImage(named: slug) }

    private var ratio: CGFloat {
        if let explicit = AspectRatioSpec.value(from: block.ratio) { return explicit }
        if let image, image.size.height > 0 { return image.size.width / image.size.height }
        return 16.0 / 9.0
    }

    private var creditText: String? {
        if let credit = block.credit, !credit.isEmpty { return credit }
        return ImageCreditStore.shared.credit(for: slug)?.formatted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if let image {
                    Color.clear
                        .aspectRatio(ratio, contentMode: .fit)
                        .overlay {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            fullscreenItem = FullscreenCourseImage(image: image, credit: creditText)
                        }
                } else {
                    Color.clear
                        .aspectRatio(ratio, contentMode: .fit)
                        .overlay { ImagePlaceholder(label: block.asset) }
                }
            }
            .frame(maxWidth: .infinity)
            .clipShape(.rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(ink, lineWidth: 2.5)
            }

            if let caption = block.caption, !caption.isEmpty {
                Text(caption)
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }

            if let creditText, !creditText.isEmpty {
                Text(creditText)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(ink.opacity(0.4))
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
}

private struct FullscreenCourseImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let credit: String?
}

private struct ImagePlaceholder: View {
    let label: String

    var body: some View {
        ZStack {
            Color.white
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.black.opacity(0.4))
                Text(label)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
        }
    }
}

// MARK: - Timeline / key dates

/// Vertical chronological timeline ("frise").
struct TimelineBlockView: View {
    let events: [TimelineEventV2]
    let accent: Color

    private let ink = Color.black

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(accent)
                            .frame(width: 16, height: 16)
                            .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                        if index < events.count - 1 {
                            Rectangle()
                                .fill(ink.opacity(0.25))
                                .frame(width: 3)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 16)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.date)
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(accent.opacity(0.30), in: Capsule())
                        Text(event.title)
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if let detail = event.detail, !detail.isEmpty {
                            Text(detail)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(ink.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, index < events.count - 1 ? 18 : 0)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .overlay { RoundedRectangle(cornerRadius: 22).strokeBorder(ink, lineWidth: 3) }
        }
    }
}

// MARK: - Quote

struct QuoteBlockView: View {
    let text: String
    let attribution: String?
    let accent: Color

    private let ink = Color.black

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\u{201C}")
                .font(.system(size: 44, weight: .black, design: .serif))
                .foregroundStyle(accent)
                .frame(height: 24, alignment: .top)
            Text(text)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .italic()
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
            if let attribution, !attribution.isEmpty {
                Text(attribution.uppercased())
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.55))
                    .tracking(0.6)
            }
        }
        .padding(.leading, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(accent)
                .frame(width: 5)
        }
    }
}

// MARK: - Fun fact / takeaway cards (restyled, glossary-aware)

/// "Le saviez-vous ?" card — restyled to match the course DA and made interactive:
/// it starts collapsed and reveals its content with a spring animation on tap.
struct FunFactCardV2: View {
    let raw: String
    let courseId: String
    let courseTitle: String
    let accent: Color
    let onGlossaryTap: (GlossaryEntry) -> Void

    @State private var revealed = false

    private let ink = Color.black

    private var title: String {
        AppLocalizable.string("course.funFact", language: AppLanguage.currentPersisted())
    }

    private var hint: String {
        switch AppLanguage.currentPersisted() {
        case .french: return "Toucher pour révéler"
        case .english: return "Tap to reveal"
        case .spanish: return "Toca para revelar"
        case .german: return "Zum Aufdecken tippen"
        case .portuguese: return "Toque para revelar"
        case .italian: return "Tocca per scoprire"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                    revealed.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(accent)
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(ink)
                    }
                    .frame(width: 36, height: 36)
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink)
                        if !revealed {
                            Text(hint)
                                .font(.system(.caption2, design: .rounded, weight: .semibold))
                                .foregroundStyle(ink.opacity(0.45))
                        }
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(ink.opacity(0.6))
                        .rotationEffect(.degrees(revealed ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if revealed {
                ProseTextView(
                    attributed: InlineAttributedBuilder.build(
                        raw: raw,
                        courseId: courseId,
                        courseTitle: courseTitle,
                        accent: UIColor(accent),
                        alignment: .left
                    ),
                    linkUnderlineColor: UIColor(accent),
                    onGlossaryTap: onGlossaryTap
                )
                .padding(.top, 14)
                .transition(.opacity)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .padding(.bottom, 4)
    }
}

/// "À retenir" key takeaway card — always the final block of a course.
struct TakeawayCardV2: View {
    let raw: String
    let courseId: String
    let courseTitle: String
    let accent: Color
    let onGlossaryTap: (GlossaryEntry) -> Void

    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)

    var body: some View {
        BrutalCallout(
            badgeIcon: "bookmark.fill",
            badgeEmoji: nil,
            badgeText: AppLocalizable.string("course.keyTakeaway", language: AppLanguage.currentPersisted()),
            badgeColor: pink
        ) {
            ProseTextView(
                attributed: InlineAttributedBuilder.build(
                    raw: raw,
                    courseId: courseId,
                    courseTitle: courseTitle,
                    accent: UIColor(accent),
                    baseBold: true,
                    alignment: .left
                ),
                linkUnderlineColor: UIColor(accent),
                onGlossaryTap: onGlossaryTap
            )
        }
    }
}

/// Shared neobrutalist callout container with a floating pill badge.
private struct BrutalCallout<Content: View>: View {
    let badgeIcon: String?
    let badgeEmoji: String?
    let badgeText: String
    let badgeColor: Color
    @ViewBuilder let content: () -> Content

    private let ink = Color.black

    var body: some View {
        ZStack(alignment: .topLeading) {
            content()
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
                if let badgeEmoji {
                    Text(badgeEmoji).font(.system(size: 14))
                }
                if let badgeIcon {
                    Image(systemName: badgeIcon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ink)
                }
                Text(badgeText)
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .tracking(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(badgeColor)
                    .overlay { Capsule().strokeBorder(.black, lineWidth: 2.5) }
            }
            .padding(.leading, 16)
        }
    }
}
