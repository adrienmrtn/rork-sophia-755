import SwiftUI

/// Horizontal paged home feed — swipe left/right to browse, explicit Start CTA to open a course.
struct HomeViewFeed: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let discountManager: DiscountOfferManager
    var isPremium: Bool = false
    @Binding var selectedCourse: Course?
    @Binding var autoSwipeCourseId: String?
    var onShowDiscountPaywall: (() -> Void)? = nil

    @State private var cards: [Course] = []
    @State private var currentIndex: Int = 0
    @State private var cardAppeared: Bool = false
    @State private var lastDiscountSwipeIndex: Int = 0

    private let cream = Color(red: 0.984, green: 0.961, blue: 0.918)
    private let ink = Color.black

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
                    VStack(spacing: 12) {
                        feedPager
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(cardAppeared ? 1 : 0)
                            .scaleEffect(cardAppeared ? 1 : 0.97)

                        pageIndicators
                            .padding(.bottom, 4)

                        browseHint
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 10)
                    .opacity(cardAppeared ? 1 : 0)
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
            handleCourseCompleted(courseId)
        }
        .onChange(of: languageManager.current) { _, _ in
            loadCards()
        }
        .onChange(of: currentIndex) { oldIndex, newIndex in
            guard oldIndex != newIndex else { return }
            registerDiscountSwipeIfNeeded(from: oldIndex, to: newIndex)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 8) {
            Image("sophia_mark")
                .resizable()
                .scaledToFit()
                .frame(height: 30)

            Spacer(minLength: 8)

            streakBadge
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 6) {
            AnimatedFlameBadge(size: 16, showGlow: false)
            Text("\(progressManager.streak)")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .monospacedDigit()
                .fixedSize(horizontal: true, vertical: true)
                .layoutPriority(1)
            Text(progressManager.streak <= 1
                ? languageManager.text("common.streak.day")
                : languageManager.text("common.streak.days"))
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .tracking(0.5)
                .fixedSize(horizontal: true, vertical: true)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .fixedSize(horizontal: true, vertical: false)
        .background(Color.white, in: Capsule())
        .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
    }

    // MARK: - Feed pager

    private var feedPager: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, course in
                FeedCourseCard(
                    course: course,
                    language: languageManager.current,
                    isFavorite: progressManager.isFavorite(course.id),
                    onToggleFavorite: {
                        progressManager.toggleFavorite(course.id)
                    },
                    onStart: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        selectedCourse = course
                    }
                )
                .padding(.horizontal, 4)
                .padding(.bottom, 6)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var pageIndicators: some View {
        HStack(spacing: 6) {
            ForEach(cards.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? ink : ink.opacity(0.2))
                    .frame(width: index == currentIndex ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentIndex)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var browseHint: some View {
        Text(languageManager.text("home.feed.swipeHint"))
            .font(.system(.caption, design: .rounded, weight: .heavy))
            .foregroundStyle(ink.opacity(0.35))
    }

    // MARK: - Deck management

    private func handleCourseCompleted(_ courseId: String) {
        guard let index = cards.firstIndex(where: { $0.id == courseId }) else {
            reloadCardsKeepingPosition()
            return
        }

        withAnimation(.snappy(duration: 0.35)) {
            cards.remove(at: index)
            if cards.isEmpty {
                currentIndex = 0
            } else if currentIndex >= cards.count {
                currentIndex = cards.count - 1
            } else if index < currentIndex {
                currentIndex = max(currentIndex - 1, 0)
            }
        }
    }

    private func reloadCardsKeepingPosition() {
        let previousCourseId = cards.indices.contains(currentIndex) ? cards[currentIndex].id : nil
        loadCards()
        if let previousCourseId,
           let newIndex = cards.firstIndex(where: { $0.id == previousCourseId }) {
            currentIndex = newIndex
        } else {
            currentIndex = min(currentIndex, max(cards.count - 1, 0))
        }
    }

    private func registerDiscountSwipeIfNeeded(from oldIndex: Int, to newIndex: Int) {
        guard !isPremium, oldIndex != newIndex else { return }
        guard lastDiscountSwipeIndex != newIndex else { return }
        lastDiscountSwipeIndex = newIndex
        discountManager.registerSwipe()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func loadCards() {
        cards = HomeDeckBuilder.deck(
            from: ContentCatalog.activeCourses,
            isCompleted: { progressManager.courseStatus(for: $0) == .completed }
        )
        currentIndex = min(currentIndex, max(cards.count - 1, 0))
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

// MARK: - Full-screen feed card with Start CTA

private struct FeedCourseCard: View {
    let course: Course
    var language: AppLanguage = .french
    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)? = nil
    let onStart: () -> Void

    @State private var cachedImage: UIImage?
    @State private var buttonTrigger: Int = 0
    @State private var startShimmer: CGFloat = -100
    @State private var startShimmerActive: Bool = false

    private let ink = Color.black
    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)
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
                        .frame(height: max(geo.size.height * 0.52, 200))

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
            startShimmerActive = true
            ShimmerAnimation.runLoop(offset: $startShimmer) { startShimmerActive }
        }
        .onDisappear {
            startShimmerActive = false
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
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            boldText(course.description)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.85))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                buttonTrigger += 1
                onStart()
            } label: {
                HStack(spacing: 8) {
                    Text(AppLocalizable.string("home.start", language: language))
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                    Image(systemName: "play.fill")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(DuolingoButtonStyle(fill: pink, shimmer: startShimmer))
            .sensoryFeedback(.impact(weight: .medium), trigger: buttonTrigger)
            .padding(.top, 4)
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
