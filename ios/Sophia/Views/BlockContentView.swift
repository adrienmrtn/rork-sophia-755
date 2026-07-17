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

            if isFirst, let dates = content.keyDates, !dates.isEmpty {
                KeyDatesCard(dates: dates, accent: accent)
            }

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
                        accent: accent,
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
            accent: accent,
            paragraphStyle: paragraphStyle
        )

        if GlossaryStore.entry(courseId: courseId, courseTitle: courseTitle, displayTerm: term) != nil,
           let url = GlossaryStore.linkURL(courseId: courseId, courseTitle: courseTitle, displayTerm: term) {
            attributes[.link] = url
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
        accent: UIColor,
        paragraphStyle: NSParagraphStyle
    ) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: roundedFont(bold: bold, italic: italic),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: bold
                ? UIColor.label
                : UIColor.label.withAlphaComponent(0.9),
        ]
        if highlight {
            attributes[.backgroundColor] = accent.withAlphaComponent(0.30)
        }
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
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = []
        textView.delegate = context.coordinator
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.label,
            .underlineColor: linkUnderlineColor,
            .underlineStyle: NSUnderlineStyle.thick.rawValue,
        ]
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.required, for: .vertical)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.onGlossaryTap = onGlossaryTap
        uiView.attributedText = attributed
        uiView.linkTextAttributes = [
            .foregroundColor: UIColor.label,
            .underlineColor: linkUnderlineColor,
            .underlineStyle: NSUnderlineStyle.thick.rawValue,
        ]
        uiView.invalidateIntrinsicContentSize()
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

    final class Coordinator: NSObject, UITextViewDelegate {
        var onGlossaryTap: (GlossaryEntry) -> Void

        init(onGlossaryTap: @escaping (GlossaryEntry) -> Void) {
            self.onGlossaryTap = onGlossaryTap
        }

        func textView(
            _ textView: UITextView,
            shouldInteractWith URL: URL,
            in characterRange: NSRange,
            interaction: UITextItemInteraction
        ) -> Bool {
            if let entry = GlossaryStore.entry(from: URL) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onGlossaryTap(entry)
            }
            return false
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

/// Compact "key dates" reference card shown at the top of the intro.
struct KeyDatesCard: View {
    let dates: [KeyDateV2]
    let accent: Color

    private let ink = Color.black

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .bold))
                Text("REPÈRES")
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .tracking(0.8)
            }
            .foregroundStyle(ink)

            ForEach(dates) { entry in
                HStack(alignment: .top, spacing: 12) {
                    Text(entry.date)
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                        .frame(minWidth: 54, alignment: .leading)
                    Text(entry.label)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(ink.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(accent.opacity(0.16))
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
                Text("— \(attribution)")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(ink.opacity(0.6))
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

/// "Le saviez-vous ?" card — neobrutalism, prose rendered natively.
struct FunFactCardV2: View {
    let raw: String
    let courseId: String
    let courseTitle: String
    let accent: Color
    let onGlossaryTap: (GlossaryEntry) -> Void

    private let mint = Color(red: 0.553, green: 0.953, blue: 0.953)

    var body: some View {
        BrutalCallout(
            badgeIcon: nil,
            badgeEmoji: "\u{1F9E0}",
            badgeText: AppLocalizable.string("course.funFact", language: AppLanguage.currentPersisted()),
            badgeColor: mint
        ) {
            ProseTextView(
                attributed: InlineAttributedBuilder.build(
                    raw: raw,
                    courseId: courseId,
                    courseTitle: courseTitle,
                    accent: UIColor(accent),
                    italic: true,
                    alignment: .left
                ),
                linkUnderlineColor: UIColor(accent),
                onGlossaryTap: onGlossaryTap
            )
        }
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
