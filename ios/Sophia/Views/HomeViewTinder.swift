import SwiftUI

struct HomeViewTinder: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let discountManager: DiscountOfferManager
    var isPremium: Bool = false
    @Binding var selectedCourse: Course?
    @Binding var autoSwipeCourseId: String?
    var onLockedTap: ((SophiaPaywallContext) -> Void)? = nil
    var onShowDiscountPaywall: (() -> Void)? = nil

    @State private var cards: [Course] = []
    @State private var topCardOffset: CGSize = .zero
    @State private var topCardRotation: Double = 0
    @State private var cardAppeared: Bool = false
    @State private var discountShimmer: CGFloat = -80
    @State private var discountShimmerActive: Bool = false

    private let cream = Color(red: 0.984, green: 0.961, blue: 0.918)
    private let ink = Color.black
    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)
    private let swipeCommitThreshold: CGFloat = 120
    private let stampFullOpacityDistance: CGFloat = 100

    private var unlockedSubjects: Set<Subject> {
        FreemiumGate.unlockedSubjects(isPremium: isPremium)
    }

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                if cards.isEmpty {
                    Spacer()
                    allCompletedView
                    Spacer()
                } else {
                    VStack(spacing: 14) {
                        cardStack
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(cardAppeared ? 1 : 0)
                            .scaleEffect(cardAppeared ? 1 : 0.97)

                        swipeActionButtons
                            .padding(.horizontal, 36)
                            .padding(.bottom, 4)
                            .opacity(cardAppeared ? 1 : 0)
                    }
                    .padding(.horizontal, 10)
                }
            }
        }
        .onAppear {
            loadCards()
            discountShimmerActive = !isPremium && discountManager.isActive
            if discountShimmerActive {
                ShimmerAnimation.runLoop(offset: $discountShimmer) { discountShimmerActive }
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                cardAppeared = true
            }
        }
        .onChange(of: discountManager.isActive) { _, active in
            discountShimmerActive = !isPremium && active
            if discountShimmerActive {
                ShimmerAnimation.runLoop(offset: $discountShimmer) { discountShimmerActive }
            } else {
                discountShimmerActive = false
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
                .frame(height: 36)

            Spacer()

            if !isPremium && discountManager.isActive {
                discountBadge
                    .transition(.scale.combined(with: .opacity))
            }

            streakBadge
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: discountManager.isActive)
    }

    private var discountBadge: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onShowDiscountPaywall?()
        } label: {
            HStack(spacing: 6) {
                AnimatedCrownBadge(size: 14)
                Text(discountManager.formattedRemaining)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(pink, in: Capsule())
            .overlay {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .mask {
                        Rectangle()
                            .frame(width: 50, height: 40)
                            .offset(x: discountShimmer)
                    }
                    .allowsHitTesting(false)
            }
            .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
        }
        .buttonStyle(.plain)
        .id(discountManager.tick)
    }

    private var streakBadge: some View {
        HStack(spacing: 6) {
            AnimatedFlameBadge(size: 16, showGlow: false)
            Text("\(progressManager.streak)")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .monospacedDigit()
            Text(progressManager.streak <= 1
                ? languageManager.text("common.streak.day")
                : languageManager.text("common.streak.days"))
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .tracking(0.5)
                .fixedSize(horizontal: true, vertical: true)
                .lineLimit(1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .frame(minWidth: 96)
        .background(Color.white, in: Capsule())
        .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
    }

    // MARK: - Card stack

    private var cardStack: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(cards.prefix(3).enumerated().reversed()), id: \.element.id) { index, course in
                    let isTop = index == 0
                    let subjectLocked = !isPremium && !unlockedSubjects.contains(course.subject)

                    TinderFlashCard(
                        course: course,
                        language: languageManager.current,
                        isFavorite: progressManager.isFavorite(course.id),
                        isSubjectLocked: subjectLocked,
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

    private func commitSwipeLeft() {
        if !isPremium && !discountManager.hasBeenTriggered {
            discountManager.triggerIfNeeded()
            onShowDiscountPaywall?()
        }
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
        cards = DeckBalancer.afterSwipe(cards, unlockedSubjects: unlockedSubjects, isPremium: isPremium)
    }

    private func openCourse(_ course: Course) {
        if let context = FreemiumGate.paywallContext(
            for: course,
            isPremium: isPremium,
            hasCompletedCourseToday: progressManager.hasCompletedCourseToday
        ) {
            onLockedTap?(context)
        } else {
            selectedCourse = course
        }
    }

    private func loadCards() {
        let filtered = ContentCatalog.activeCourses
            .filter { progressManager.courseStatus(for: $0.id) != .completed }
        cards = DeckBalancer.balancedDeck(
            courses: filtered,
            unlockedSubjects: unlockedSubjects,
            isPremium: isPremium
        )
        let preloadIds = cards.prefix(5).map(\.id)
        CourseImageMap.preloadImages(for: preloadIds)
    }

    private var allCompletedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(ink)
            Text(languageManager.text("home.bravo"))
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
            Text(languageManager.text("home.allCompleted"))
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(ink.opacity(0.6))
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
    var isSubjectLocked: Bool = false
    var onToggleFavorite: (() -> Void)? = nil

    @State private var cachedImage: UIImage?

    private let ink = Color.black
    private let depth: CGFloat = 3

    private var pastel: Color {
        switch course.subject {
        case .histoire: return Color(red: 1.0, green: 0.86, blue: 0.62)
        case .sciences: return Color(red: 0.70, green: 0.95, blue: 0.80)
        case .litterature: return Color(red: 1.0, green: 0.78, blue: 0.78)
        case .art: return Color(red: 0.66, green: 0.92, blue: 0.96)
        case .mythologie: return Color(red: 0.82, green: 0.78, blue: 1.0)
        case .comprendreLeMonde: return Color(red: 0.74, green: 0.90, blue: 1.0)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(ink)
                .offset(y: depth)

            GeometryReader { geo in
                VStack(spacing: 0) {
                    courseIllustration
                        .frame(height: max(geo.size.height * 0.58, 220))

                    bottomPanel
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .background(pastel)
            }
            .clipShape(.rect(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(ink, lineWidth: 3)
            }
        }
        .padding(.bottom, depth)
        .onAppear {
            if cachedImage == nil {
                cachedImage = CourseImageMap.loadImage(for: course.id)
            }
        }
    }

    private var courseIllustration: some View {
        Color(.secondarySystemBackground)
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
                        pastel
                        Text(course.subject.emoji)
                            .font(.system(size: 72))
                    }
                }
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, ink.opacity(0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 48)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(ink)
                    .frame(height: 3)
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onToggleFavorite?()
                } label: {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(ink)
                        .frame(width: 40, height: 40)
                        .background(Color.white, in: Circle())
                        .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                }
                .padding(14)
            }
            .overlay(alignment: .topLeading) {
                if isSubjectLocked {
                    HStack(spacing: 5) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(AppLocalizable.string("home.locked", language: language))
                            .font(.system(.caption2, design: .rounded, weight: .heavy))
                            .tracking(0.3)
                    }
                    .foregroundStyle(ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white, in: Capsule())
                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                    .padding(14)
                }
            }
    }

    private var bottomPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(course.subject.emoji)
                    .font(.system(size: 16))
                Text(course.subject.localizedShortName(language: language).uppercased())
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(0.5)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(ink, in: Capsule())

            Text(course.title)
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            boldText(course.description)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.85))
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func boldText(_ input: String) -> Text {
        let parts = input.components(separatedBy: "**")
        var result = Text("")
        for (index, part) in parts.enumerated() {
            if index % 2 == 1 {
                result = result + Text(part).bold()
            } else {
                result = result + Text(part)
            }
        }
        return result
    }
}

// MARK: - Neo-brutalist swipe controls

private enum SwipeActionKind {
    case accept
    case reject
}

private struct SwipeActionButton: View {
    let kind: SwipeActionKind
    let action: () -> Void

    private let ink = Color.black
    private let acceptFill = Color(red: 0.62, green: 0.94, blue: 0.72)
    private let rejectFill = Color(red: 1.0, green: 0.55, blue: 0.58)
    private let depth: CGFloat = 4
    private let size: CGFloat = 60

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(ink)
                    .offset(y: depth)
                    .frame(width: size, height: size)

                Circle()
                    .fill(kind == .accept ? acceptFill : rejectFill)
                    .overlay {
                        Circle().strokeBorder(ink, lineWidth: 3)
                    }
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: kind == .accept ? "checkmark" : "xmark")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundStyle(ink)
                    }
            }
            .padding(.bottom, depth)
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

    private let ink = Color.black
    private let acceptFill = Color(red: 0.62, green: 0.94, blue: 0.72)
    private let rejectFill = Color(red: 1.0, green: 0.55, blue: 0.58)
    private let depth: CGFloat = 4

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ink)
                .offset(x: depth * 0.6, y: depth)
                .frame(width: 68, height: 68)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(kind == .accept ? acceptFill : rejectFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(ink, lineWidth: 3)
                }
                .frame(width: 68, height: 68)
                .overlay {
                    Image(systemName: kind == .accept ? "checkmark" : "xmark")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(ink)
                }
        }
        .padding(.bottom, depth)
        .rotationEffect(.degrees(kind == .accept ? -14 : 14))
        .opacity(Double(progress))
        .scaleEffect(0.82 + 0.18 * progress)
    }
}
