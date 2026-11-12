import SwiftUI

// The "zigzag of cards" trail of the Parcours tab: every course of a level is a card with
// its cover, alternately on the left and on the right, joined to the next one by a dotted
// curve. The level closes on a quiz pill, and the levels still locked fold into a compact
// card. The pods of the previous trail live on in `PathNodeViews.swift` for the onboarding
// preview.

// MARK: - Layout

/// Geometry of the card trail. The connector is anchored on the bottom of its own row, so
/// the cards can be as tall as their title needs.
enum PathCardLayout {
    static let cardWidth: CGFloat = 186
    /// The course to read now is drawn wider.
    static let currentCardWidth: CGFloat = 214
    static let coverHeight: CGFloat = 78
    static let currentCoverHeight: CGFloat = 110
    static let rowSpacing: CGFloat = 14
    static let sideInset: CGFloat = 24
    /// Past this width the cards would drift apart and the connector no longer reach.
    static let maxTrailWidth: CGFloat = 420
    static let maxSectionWidth: CGFloat = 520
    static let quizPillWidth: CGFloat = 230

    /// Box of the dotted curve, hung under the card it starts from.
    static let connectorWidth: CGFloat = 120
    /// The last course only has to reach the quiz pill, in the middle.
    static let quizConnectorWidth: CGFloat = 56
    static let connectorHeight: CGFloat = 60
    /// How far the box hangs below the bottom edge of its row.
    static let connectorDrop: CGFloat = 34
    /// Distance from the card's outer edge to where the curve starts.
    static let connectorStartX: CGFloat = 150

    /// Courses alternate sides, the first one on the leading edge.
    static func isLeading(_ index: Int) -> Bool {
        index % 2 == 0
    }
}

// MARK: - Palette

/// Colours of the trail that carry a meaning of their own (done, not reached yet, reward).
enum PathCardPalette {
    /// Bright green of what is behind the reader: check badge, travelled dots.
    static let done = Color(red: 0.247, green: 0.749, blue: 0.561)
    /// Dots not travelled yet, dashed outline of the quiz to come.
    static let trailIdle = Color(red: 0.765, green: 0.796, blue: 0.847)
    /// Cover of a course still locked.
    static let lockedCover = Color(red: 0.933, green: 0.941, blue: 0.953)
    /// Night-blue veil over a level's cover, so its title reads on any artwork.
    static let bannerVeil = Color(red: 0.051, green: 0.094, blue: 0.176)
    /// Pale gold behind a trophy or a reward chip.
    static let goldTint = Color(red: 0.984, green: 0.937, blue: 0.788)
    /// Text on pale gold.
    static let goldInk = Color(red: 0.420, green: 0.306, blue: 0.0)
}

// MARK: - Padlock

/// A padlock that swings open when `isOpen` flips inside an animation.
struct PathLockGlyph: View {
    let isOpen: Bool
    var size: CGFloat = 20
    var color: Color = DS.inkTertiary

    var body: some View {
        Image(systemName: isOpen ? "lock.open" : "lock")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(isOpen ? DS.accent : color)
            .contentTransition(.symbolEffect(.replace))
            .scaleEffect(isOpen ? 1.18 : 1)
            .accessibilityHidden(true)
    }
}

// MARK: - Course card

/// One course of a level: its cover, "COURSE n" and its title. Checked in green once read,
/// wider and ringed in blue with its button while it is the one to read, grey under a
/// padlock while locked.
struct PathCourseCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    /// Rank of the course in its level, from 1.
    let number: Int
    let state: PathNodeState
    let isCurrent: Bool
    /// The padlock is opening, just before the card is uncovered.
    var isUnlocking: Bool = false

    private var width: CGFloat {
        isCurrent ? PathCardLayout.currentCardWidth : PathCardLayout.cardWidth
    }

    private var coverHeight: CGFloat {
        isCurrent ? PathCardLayout.currentCoverHeight : PathCardLayout.coverHeight
    }

    private var borderColor: Color {
        isCurrent ? DS.accent : DS.hairline
    }

    private var eyebrowColor: Color {
        switch state {
        case .completed: return DS.success
        case .available: return DS.accent
        case .locked: return DS.inkTertiary
        }
    }

    private var eyebrow: String {
        String(format: languageManager.text("elevatePath.course.number"), number)
            .uppercased(with: languageManager.current.foundationLocale)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cover
            texts
        }
        .frame(width: width)
        .background(DS.surface)
        .clipShape(cardShape)
        .overlay {
            cardShape.strokeBorder(borderColor, lineWidth: 1.5)
        }
        .background {
            // The slightly thicker bottom edge of the style.
            cardShape.fill(borderColor).offset(y: 1.5)
        }
        .contentShape(cardShape)
    }

    // MARK: Cover

    private var cover: some View {
        // The cover is an overlay of a fixed box: whatever the artwork's ratio, it can
        // neither widen nor heighten the card.
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: coverHeight)
            .overlay { coverContent }
            .clipped()
            .overlay(alignment: .topTrailing) {
                if state == .completed {
                    doneBadge
                        .padding(8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .overlay(alignment: .topLeading) {
                if isCurrent {
                    readNowChip
                        .padding(8)
                        .transition(.scale(scale: 0.8, anchor: .topLeading).combined(with: .opacity))
                }
            }
    }

    @ViewBuilder
    private var coverContent: some View {
        if state == .locked {
            ZStack {
                PathCardPalette.lockedCover
                PathLockGlyph(isOpen: isUnlocking, size: 20)
            }
            .transition(.opacity)
        } else {
            CourseCover(course: course, cornerRadius: 0)
                .transition(.opacity)
        }
    }

    private var doneBadge: some View {
        DSCheckBadge(size: 26, fill: PathCardPalette.done)
            .overlay {
                Circle().strokeBorder(Color.white, lineWidth: 2)
            }
    }

    private var readNowChip: some View {
        Text(languageManager.text("elevatePath.course.readNow"))
            .font(DS.sans(.caption2, .bold))
            .foregroundStyle(DS.accent)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(DS.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: Texts

    private var texts: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(eyebrow)
                .font(DS.sans(.caption2, .bold))
                .tracking(0.8)
                .foregroundStyle(eyebrowColor)
                .lineLimit(1)

            Text(course.title.withoutInlineMarkup)
                .font(isCurrent ? DS.sans(.subheadline, .bold) : DS.sans(.footnote, .semibold))
                .foregroundStyle(state == .locked ? DS.inkTertiary : DS.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            if isCurrent {
                PathStartLabel(text: languageManager.text("home.start"))
                    .padding(.top, 6)
                    .transition(.opacity)
            }
        }
        .padding(.top, 9)
        .padding(.horizontal, 11)
        .padding(.bottom, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The blue "Start" bar at the foot of the card to play. It is drawn, not a button of its
/// own: the whole card is the button.
struct PathStartLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DS.sans(.subheadline, .semibold))
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(DS.accent, in: RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
    }
}

// MARK: - Quiz pill

/// The quiz that closes a level: a dashed outline while its courses are not all read, a
/// card with its "Start" bar once it can be taken, checked once passed.
struct PathQuizPill: View {
    @Environment(LanguageManager.self) private var languageManager
    let state: PathNodeState
    let isCurrent: Bool
    let courseCount: Int
    let completedCourseCount: Int
    /// The quiz is about to open: its dashed outline lights up before it turns into a card.
    var isUnlocking: Bool = false

    private var pillShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
    }

    private var subtitle: String {
        switch state {
        case .locked:
            if courseCount > 1 {
                return String(format: languageManager.text("elevatePath.quiz.afterCourses"), courseCount)
            }
            return languageManager.text("path.status.locked")
        case .available:
            return String(format: languageManager.text("path.courses.count"), completedCourseCount, courseCount)
        case .completed:
            return languageManager.text("path.status.passed")
        }
    }

    private var subtitleColor: Color {
        switch state {
        case .locked: return DS.inkTertiary
        case .available: return DS.inkSecondary
        case .completed: return DS.success
        }
    }

    private var solidBorderColor: Color {
        isCurrent ? DS.accent : DS.hairline
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                icon

                VStack(alignment: .leading, spacing: 2) {
                    Text(languageManager.text("path.quizPod"))
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(state == .locked ? DS.inkSecondary : DS.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(subtitle)
                        .font(DS.sans(.caption))
                        .foregroundStyle(subtitleColor)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if state == .completed {
                    DSCheckBadge(size: 24, fill: PathCardPalette.done)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            if isCurrent {
                PathStartLabel(text: languageManager.text("home.start"))
                    .transition(.opacity)
            }
        }
        .padding(12)
        .frame(width: PathCardLayout.quizPillWidth)
        .background {
            pillShape.fill(DS.surface)
        }
        .overlay { border }
        .background {
            if state != .locked {
                pillShape.fill(solidBorderColor).offset(y: 1.5)
            }
        }
        .contentShape(pillShape)
    }

    @ViewBuilder
    private var border: some View {
        if state == .locked {
            pillShape.strokeBorder(
                isUnlocking ? DS.accent : PathCardPalette.trailIdle,
                style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
            )
        } else {
            pillShape.strokeBorder(solidBorderColor, lineWidth: 1.5)
        }
    }

    @ViewBuilder
    private var icon: some View {
        if state == .locked {
            Image(systemName: "trophy")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isUnlocking ? DS.accent : DS.inkTertiary)
                .frame(width: 34, height: 34)
        } else {
            Image(systemName: "trophy.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 34, height: 34)
                .background(PathPalette.gold, in: Circle())
        }
    }
}

// MARK: - Locked level

/// A level still locked, folded into one row: greyed cover, "LEVEL n", its title and the
/// padlock, which rattles on a tap and swings open when the level is won.
struct PathLockedLevelCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let level: PathLevel
    let accentIndex: Int
    /// Bump by one inside `withAnimation` to rattle the padlock.
    var lockShakes: CGFloat = 0
    /// The padlock is opening, just before the level unfolds.
    var isOpening: Bool = false

    private var caption: String {
        let levelText = String(format: languageManager.text("path.levelCaption"), level.number)
        let coursesText = String(format: languageManager.text("path.courses.count"), level.completedCourseCount, level.courseCount)
        return "\(levelText) · \(coursesText)".uppercased(with: languageManager.current.foundationLocale)
    }

    var body: some View {
        HStack(spacing: 12) {
            CollectionCoverView(collection: level.collection, accentIndex: accentIndex)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
                .grayscale(1)
                .opacity(0.6)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(caption)
                    .font(DS.sans(.caption2, .bold))
                    .tracking(1)
                    .foregroundStyle(DS.inkTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(level.collection.title)
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            PathLockGlyph(isOpen: isOpening, size: 16)
                .frame(width: 24, height: 24)
                .modifier(PathShakeEffect(shakes: lockShakes, amplitude: 5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .dsCard(padding: nil)
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }
}

// MARK: - Breathing halo

/// A soft blue glow breathing behind the card to play. It is a view of its own, laid
/// behind the card, so the card itself keeps its identity when it stops being the current
/// one. `phaseAnimator` keeps the loop inside this view (a `withAnimation(.repeatForever)`
/// started in `onAppear` leaks into the lazy trail around it).
struct PathCardHalo: View {
    var cornerRadius: CGFloat = DS.Radius.card + 5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var phases: [Bool] {
        reduceMotion ? [false] : [false, true]
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(DS.accent.opacity(0.16))
            .padding(-5)
            .phaseAnimator(phases) { content, expanded in
                content
                    .scaleEffect(expanded ? 1.02 : 0.99)
                    .opacity(expanded ? 0.3 : 1)
            } animation: { _ in
                .easeInOut(duration: 1.5)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Dotted connector

/// The lying-S curve from one card down to the next, in the box hung under the first one.
/// Only its middle stretch is kept: both ends would sit under the cards anyway.
struct PathConnectorCurve: Shape {
    /// `true` when the curve leaves a leading card towards a trailing one.
    let towardsTrailing: Bool

    func path(in rect: CGRect) -> Path {
        let startX: CGFloat = towardsTrailing ? rect.minX : rect.maxX
        let endX: CGFloat = towardsTrailing ? rect.maxX : rect.minX
        let top: CGFloat = rect.minY + rect.height / 6
        let bottom: CGFloat = rect.maxY - rect.height / 6

        var curve = Path()
        curve.move(to: CGPoint(x: startX, y: top))
        curve.addCurve(
            to: CGPoint(x: endX, y: bottom),
            control1: CGPoint(x: rect.midX, y: top),
            control2: CGPoint(x: rect.midX, y: bottom)
        )
        return curve.trimmedPath(from: 0.2, to: 0.8)
    }
}

/// Dotted link between two rows. The grey dots draw themselves when the row comes in; the
/// green ones follow `fill`, which the page animates when a course has just been finished.
struct PathDottedConnector: View {
    let towardsTrailing: Bool
    /// Travelled share of the link, from 0 to 1.
    let fill: CGFloat
    var width: CGFloat = PathCardLayout.connectorWidth
    /// Lets the cards settle before the dots are drawn.
    var appearDelay: Double = 0

    @State private var drawn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var dots: StrokeStyle {
        StrokeStyle(lineWidth: 3, lineCap: .round, dash: [1, 9])
    }

    var body: some View {
        ZStack {
            PathConnectorCurve(towardsTrailing: towardsTrailing)
                .trim(from: 0, to: drawn ? 1 : 0)
                .stroke(PathCardPalette.trailIdle, style: dots)
            PathConnectorCurve(towardsTrailing: towardsTrailing)
                .trim(from: 0, to: drawn ? fill : 0)
                .stroke(PathCardPalette.done, style: dots)
        }
        .frame(width: width, height: PathCardLayout.connectorHeight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !drawn else { return }
            if reduceMotion {
                drawn = true
            } else {
                withAnimation(.easeOut(duration: 0.55).delay(appearDelay)) {
                    drawn = true
                }
            }
        }
    }
}
