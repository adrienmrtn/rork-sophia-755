import SwiftUI

/// Full-bleed horizontal pager for the home course feed — TikTok-style browsing: swiping
/// left/right only moves between courses (native `.page` `TabView`, no custom drag math),
/// it never opens anything. Opening a course always goes through the explicit "Commencer"
/// CTA on the card. Kept alongside `HomeViewLegacy`/`HomeViewTinder` for one-flag rollback
/// via `HomeCardPresentation.style`.
struct HomeViewTikTok: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let discountManager: DiscountOfferManager
    var isPremium: Bool = false
    @Binding var selectedCourse: Course?
    @Binding var autoSwipeCourseId: String?
    var onShowDiscountPaywall: (() -> Void)? = nil

    @State private var cards: [Course] = []
    @State private var selectedCardId: String = ""
    @State private var cardAppeared = false
    /// Set right before a *programmatic* page change (auto-advance after a course was
    /// opened/dismissed), so it doesn't get counted as a genuine browsing swipe.
    @State private var suppressNextSwipeCount = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if cards.isEmpty {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, DS.Space.l)
                        .padding(.top, 8)
                        .padding(.bottom, DS.Space.s)
                    Spacer()
                    allCompletedView
                    Spacer()
                }
                .background(DS.canvas.ignoresSafeArea())
            } else {
                TabView(selection: $selectedCardId) {
                    ForEach(cards) { course in
                        TikTokCourseCard(
                            course: course,
                            language: languageManager.current,
                            isFavorite: progressManager.isFavorite(course.id),
                            onToggleFavorite: {
                                progressManager.toggleFavorite(course.id)
                            },
                            onStart: {
                                startCourse(course)
                            }
                        )
                        .tag(course.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .opacity(cardAppeared ? 1 : 0)
                .scaleEffect(cardAppeared ? 1 : 0.97)
                .onChange(of: selectedCardId) { oldValue, _ in
                    guard !oldValue.isEmpty else { return }
                    if suppressNextSwipeCount {
                        suppressNextSwipeCount = false
                        return
                    }
                    registerDiscountSwipe()
                }

                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, DS.Space.l)
                        .padding(.top, 8)
                    Spacer()
                }
                .opacity(cardAppeared ? 1 : 0)
            }
        }
        .onAppear {
            loadCards()
            withAnimation(.easeOut(duration: 0.35).delay(0.1)) {
                cardAppeared = true
            }
        }
        .onChange(of: autoSwipeCourseId) { _, newId in
            guard let courseId = newId else { return }
            autoSwipeCourseId = nil
            advancePast(courseId: courseId)
        }
        .onChange(of: languageManager.current) { _, _ in
            loadCards()
        }
    }

    // MARK: - Header (floats over the full-bleed pager)

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 8) {
            Image("sophia_mark")
                .resizable()
                .scaledToFit()
                .frame(height: 28)
                .shadow(color: .black.opacity(0.35), radius: 6, y: 1)

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
        .dsSoftShadow()
    }

    // MARK: - Actions

    private func startCourse(_ course: Course) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        selectedCourse = course
    }

    private func registerDiscountSwipe() {
        guard !isPremium else { return }
        discountManager.registerSwipe()
    }

    /// Called when a course is dismissed after being opened from the feed: cycles it to the
    /// end of the deck (same "come back to it later" semantics as the Tinder/legacy skip)
    /// and pages to whichever course now takes its place, without counting it as a swipe.
    private func advancePast(courseId: String) {
        guard let index = cards.firstIndex(where: { $0.id == courseId }) else { return }
        let finished = cards.remove(at: index)
        cards.append(finished)
        let nextId = cards.indices.contains(index) ? cards[index].id : (cards.first?.id ?? "")
        guard nextId != selectedCardId else { return }
        suppressNextSwipeCount = true
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedCardId = nextId
        }
    }

    private func loadCards() {
        cards = HomeDeckBuilder.deck(
            from: ContentCatalog.activeCourses,
            isCompleted: { progressManager.courseStatus(for: $0) == .completed }
        )
        selectedCardId = cards.first?.id ?? ""
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

// MARK: - Full-bleed course page

private struct TikTokCourseCard: View {
    let course: Course
    var language: AppLanguage = .french
    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)? = nil
    let onStart: () -> Void

    @State private var cachedImage: UIImage?
    @State private var startTrigger: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer

            LinearGradient(
                colors: [.clear, .black.opacity(0.15), .black.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            HStack(alignment: .bottom, spacing: 14) {
                contentPanel
                favoriteButton
            }
            .padding(.horizontal, DS.Space.l)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            if cachedImage == nil {
                cachedImage = CourseImageMap.loadImage(for: course.id)
            }
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let cachedImage {
            Image(uiImage: cachedImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .allowsHitTesting(false)
        } else {
            ZStack {
                LinearGradient(colors: [DS.accent, DS.accent.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                Image(systemName: course.subject.icon)
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var contentPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(course.subject.localizedShortName(language: language).uppercased())
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .tracking(1.2)

            Text(course.title)
                .font(DS.title(.title2, .bold))
                .foregroundStyle(.white)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            boldText(course.description)
                .font(DS.sans(.subheadline))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(3)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                startTrigger += 1
                onStart()
            } label: {
                HStack(spacing: 8) {
                    Text(AppLocalizable.string("home.start", language: language))
                    Image(systemName: "play.fill")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .buttonStyle(DSPrimaryButtonStyle(fill: .white, foreground: DS.ink))
            .frame(maxWidth: 200)
            .padding(.top, 6)
            .sensoryFeedback(.impact(weight: .medium), trigger: startTrigger)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var favoriteButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onToggleFavorite?()
        } label: {
            Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(.black.opacity(0.35), in: Circle())
                .overlay { Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 1) }
        }
        .padding(.bottom, 4)
    }

    private func boldText(_ input: String) -> Text {
        let parts = input.components(separatedBy: "**")
        var result = Text("")
        for (index, part) in parts.enumerated() {
            if index % 2 == 1 {
                result = result + Text(part).fontWeight(.bold).foregroundColor(.white)
            } else {
                result = result + Text(part)
            }
        }
        return result
    }
}
