import SwiftUI

struct HomeViewTinder: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let discountManager: DiscountOfferManager
    var isPremium: Bool = false
    @Binding var selectedCourse: Course?
    @Binding var autoSwipeCourseId: String?
    var onShowDiscountPaywall: (() -> Void)? = nil

    @State private var cards: [Course] = []
    @State private var topCardOffset: CGSize = .zero
    @State private var topCardRotation: Double = 0
    @State private var cardAppeared: Bool = false

    private let swipeCommitThreshold: CGFloat = 120
    private let stampFullOpacityDistance: CGFloat = 100

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, DS.Space.l)
                    .padding(.top, 8)
                    .padding(.bottom, DS.Space.s)

                if cards.isEmpty {
                    Spacer()
                    allCompletedView
                    Spacer()
                } else {
                    VStack(spacing: DS.Space.l) {
                        cardStack
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(cardAppeared ? 1 : 0)
                            .scaleEffect(cardAppeared ? 1 : 0.97)

                        swipeActionButtons
                            .padding(.horizontal, 40)
                            .padding(.bottom, 4)
                            .opacity(cardAppeared ? 1 : 0)
                    }
                    .padding(.horizontal, DS.Space.m)
                    .padding(.bottom, 4)
                }
            }
        }
        .onAppear {
            loadCards()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                cardAppeared = true
            }
        }
        .onChange(of: autoSwipeCourseId) { _, newId in
            guard let courseId = newId else { return }
            autoSwipeCourseId = nil
            if let firstCard = cards.first, firstCard.id == courseId {
                performAutoSwipeLeft()
            }
        }
        .onChange(of: languageManager.current) { _, _ in
            loadCards()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 8) {
            Image("sophia_mark")
                .resizable()
                .scaledToFit()
                .frame(height: 28)

            Spacer(minLength: 8)

            streakBadge
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DS.inkSecondary)
            Text("\(progressManager.streak)")
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .fixedSize(horizontal: true, vertical: true)
                .layoutPriority(1)
            Text(progressManager.streak <= 1
                ? languageManager.text("common.streak.day")
                : languageManager.text("common.streak.days"))
                .font(DS.sans(.caption, .medium))
                .foregroundStyle(DS.inkSecondary)
                .fixedSize(horizontal: true, vertical: true)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .fixedSize(horizontal: true, vertical: false)
        .background(DS.surface, in: Capsule())
        .overlay { Capsule().strokeBorder(DS.hairline, lineWidth: 1) }
    }

    // MARK: - Card stack

    private var cardStack: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(cards.prefix(3).enumerated().reversed()), id: \.element.id) { index, course in
                    let isTop = index == 0

                    TinderFlashCard(
                        course: course,
                        language: languageManager.current,
                        isFavorite: progressManager.isFavorite(course.id),
                        onToggleFavorite: {
                            progressManager.toggleFavorite(course.id)
                        }
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .overlay {
                        if isTop {
                            swipeStampOverlay
                        }
                    }
                    .offset(
                        x: isTop ? topCardOffset.width : 0,
                        y: isTop ? topCardOffset.height : CGFloat(index) * 10
                    )
                    .scaleEffect(isTop ? 1.0 : 1.0 - CGFloat(index) * 0.035)
                    .rotationEffect(.degrees(isTop ? topCardRotation : 0))
                    .zIndex(Double(3 - index))
                    .gesture(isTop ? dragGesture(for: course) : nil)
                    .animation(.snappy(duration: 0.3), value: topCardOffset)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private var swipeStampOverlay: some View {
        ZStack {
            SwipeStampIcon(
                kind: .accept,
                progress: stampProgress(for: topCardOffset.width, direction: 1)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)

            SwipeStampIcon(
                kind: .reject,
                progress: stampProgress(for: topCardOffset.width, direction: -1)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(24)
        }
        .allowsHitTesting(false)
    }

    private func stampProgress(for width: CGFloat, direction: CGFloat) -> CGFloat {
        let raw = width / stampFullOpacityDistance * direction
        return min(max(raw, 0), 1)
    }

    private var swipeActionButtons: some View {
        HStack {
            SwipeActionButton(kind: .reject) {
                commitSwipeLeft()
            }

            Spacer()

            SwipeActionButton(kind: .accept) {
                guard let course = cards.first else { return }
                commitSwipeRight(for: course)
            }
        }
    }

    // MARK: - Gestures

    private func dragGesture(for course: Course) -> some Gesture {
        DragGesture()
            .onChanged { value in
                topCardOffset = value.translation
                topCardRotation = Double(value.translation.width / 22)
            }
            .onEnded { value in
                let velocity = value.velocity.width

                if value.translation.width > swipeCommitThreshold
                    || (velocity > 800 && value.translation.width > 0) {
                    commitSwipeRight(for: course)
                } else if value.translation.width < -swipeCommitThreshold
                    || (velocity < -800 && value.translation.width < 0) {
                    commitSwipeLeft()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                        topCardOffset = .zero
                        topCardRotation = 0
                    }
                }
            }
    }

    private func commitSwipeRight(for course: Course) {
        registerDiscountSwipe()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.snappy(duration: 0.35)) {
            topCardOffset = CGSize(width: 520, height: topCardOffset.height)
            topCardRotation = 18
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            topCardOffset = .zero
            topCardRotation = 0
            openCourse(course)
        }
    }

    private func registerDiscountSwipe() {
        guard !isPremium else { return }
        discountManager.registerSwipe()
    }

    private func commitSwipeLeft() {
        registerDiscountSwipe()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.snappy(duration: 0.35)) {
            topCardOffset = CGSize(width: -520, height: topCardOffset.height)
            topCardRotation = -18
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            cycleTopCard()
            topCardOffset = .zero
            topCardRotation = 0
        }
    }

    private func performAutoSwipeLeft() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.snappy(duration: 0.45)) {
            topCardOffset = CGSize(width: -520, height: 0)
            topCardRotation = -18
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            cycleTopCard()
            topCardOffset = .zero
            topCardRotation = 0
        }
    }

    private func cycleTopCard() {
        guard !cards.isEmpty else { return }
        let removed = cards.removeFirst()
        cards.append(removed)
    }

    private func openCourse(_ course: Course) {
        selectedCourse = course
    }

    private func loadCards() {
        cards = HomeDeckBuilder.deck(
            from: ContentCatalog.activeCourses,
            isCompleted: { progressManager.courseStatus(for: $0) == .completed }
        )
        let preloadIds = cards.prefix(5).map(\.id)
        CourseImageMap.preloadImages(for: preloadIds)
    }

    private var allCompletedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(DS.accentSoft)
            Text(languageManager.text("home.bravo"))
                .font(DS.title(.title, .semibold))
                .foregroundStyle(DS.ink)
            Text(languageManager.text("home.allCompleted"))
                .font(DS.sans(.body))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Full-screen course card

private struct TinderFlashCard: View {
    let course: Course
    var language: AppLanguage = .french
    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)? = nil

    @State private var cachedImage: UIImage?

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                courseIllustration
                    .frame(height: max(geo.size.height * 0.56, 220))

                bottomPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(DS.surface)
        }
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
        .onAppear {
            if cachedImage == nil {
                cachedImage = CourseImageMap.loadImage(for: course.id)
            }
        }
    }

    private var courseIllustration: some View {
        DS.surfaceMuted
            .overlay {
                if let uiImage = cachedImage {
                    Color.clear
                        .overlay {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                        .allowsHitTesting(false)
                } else {
                    ZStack {
                        DS.surfaceMuted
                        Image(systemName: course.subject.icon)
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(DS.accentSoft.opacity(0.5))
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onToggleFavorite?()
                } label: {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(isFavorite ? DS.accent : DS.inkSecondary)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
                }
                .padding(14)
            }
    }

    private var bottomPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(course.subject.localizedShortName(language: language).uppercased())
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(DS.accentSoft)
                .tracking(1.2)

            Text(course.title)
                .font(DS.title(.title2, .semibold))
                .foregroundStyle(DS.ink)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            boldText(course.description)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .lineSpacing(3)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DS.Space.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func boldText(_ input: String) -> Text {
        let parts = input.components(separatedBy: "**")
        var result = Text("")
        for (index, part) in parts.enumerated() {
            if index % 2 == 1 {
                result = result + Text(part).fontWeight(.semibold).foregroundColor(DS.ink)
            } else {
                result = result + Text(part)
            }
        }
        return result
    }
}

// MARK: - Calm swipe controls

private enum SwipeActionKind {
    case accept
    case reject
}

private struct SwipeActionButton: View {
    let kind: SwipeActionKind
    let action: () -> Void

    private let size: CGFloat = 58

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            Circle()
                .fill(kind == .accept ? DS.accent : DS.surface)
                .frame(width: size, height: size)
                .overlay {
                    Circle().strokeBorder(kind == .accept ? Color.clear : DS.hairline, lineWidth: 1)
                }
                .overlay {
                    Image(systemName: kind == .accept ? "arrow.right" : "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(kind == .accept ? Color.white : DS.inkSecondary)
                }
                .dsSoftShadow()
        }
        .buttonStyle(.plain)
    }
}

private struct SwipeStampIcon: View {
    enum Kind {
        case accept
        case reject
    }

    let kind: Kind
    let progress: CGFloat

    var body: some View {
        Text(kind == .accept
             ? AppLocalizable.string("home.start", language: AppLanguage.currentPersisted())
             : AppLocalizable.string("home.skip", language: AppLanguage.currentPersisted()))
            .font(DS.sans(.subheadline, .semibold))
            .tracking(1.5)
            .foregroundStyle(kind == .accept ? DS.accent : DS.inkSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(DS.surface, in: Capsule())
            .overlay {
                Capsule().strokeBorder(kind == .accept ? DS.accent : DS.hairline, lineWidth: 1.5)
            }
            .rotationEffect(.degrees(kind == .accept ? -10 : 10))
            .opacity(Double(progress))
            .scaleEffect(0.85 + 0.15 * progress)
    }
}
