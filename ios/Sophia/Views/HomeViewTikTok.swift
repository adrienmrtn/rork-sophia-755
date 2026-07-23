import SwiftUI

/// Walks up from an invisible probe view to the enclosing `UIScrollView` and disables
/// `delaysContentTouches`, so buttons inside the feed (the "Commencer" CTA) fire on the first
/// tap even while the scroll is still settling after a swipe — instead of the first tap being
/// swallowed to stop the scroll. Also keeps `canCancelContentTouches` so vertical swiping that
/// starts on the card still scrolls.
private struct ImmediateTouchScrollFixer: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let probe = UIView(frame: .zero)
        probe.isUserInteractionEnabled = false
        DispatchQueue.main.async { [weak probe] in
            var view: UIView? = probe
            while let current = view {
                if let scroll = current as? UIScrollView {
                    scroll.delaysContentTouches = false
                    scroll.canCancelContentTouches = true
                    break
                }
                view = current.superview
            }
        }
        return probe
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

/// Home course feed: a calm, inset card (Deepstash-style — rounded corners, contained
/// image + text, explicit CTA) paged one at a time with a vertical scroll-snap gesture
/// (the "meta" of a TikTok/Reels feed: swipe up/down to move between courses), rather than
/// a full-bleed video-style card. Swiping only browses — opening a course always goes
/// through the explicit "Commencer" CTA on the card. Kept alongside `HomeViewLegacy`/
/// `HomeViewTinder` for one-flag rollback via `HomeCardPresentation.style`.
struct HomeViewTikTok: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let discountManager: DiscountOfferManager
    var isPremium: Bool = false
    @Binding var selectedCourse: Course?
    @Binding var autoSwipeCourseId: String?
    var onShowDiscountPaywall: (() -> Void)? = nil

    @State private var cards: [Course] = []
    @State private var scrolledCardId: String?
    @State private var cardAppeared = false
    /// Set right before a *programmatic* page change (auto-advance after a course was
    /// opened/dismissed), so it doesn't get counted as a genuine browsing swipe.
    @State private var suppressNextSwipeCount = false
    @State private var showSwipeExplain = false

    /// Hauteur laissée visible en bas de chaque carte pour laisser **entrapercevoir** la
    /// carte suivante (« il y en a d'autres en dessous »). Chaque rangée fait donc un peu
    /// moins qu'un plein écran, tout en gardant le snap une-carte-par-swipe (`.viewAligned`).
    /// La carte est alignée en haut de sa rangée (voir `TikTokCourseCard`) pour que ce «peek»
    /// montre bien le **début** de la carte suivante, et non du vide au-dessus d'elle.
    private let peekHeight: CGFloat = 120

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
                    GeometryReader { geo in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 0) {
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
                                    // Chaque rangée fait presque un plein écran (moins
                                    // `peekHeight`) : `.viewAligned` snappe toujours une carte
                                    // par swipe, mais le haut de la carte suivante dépasse en
                                    // bas de l'écran pour signaler qu'il y a d'autres cours.
                                    .frame(width: geo.size.width, height: geo.size.height - peekHeight)
                                    .id(course.id)
                                }
                            }
                            .scrollTargetLayout()
                            // Le tap sur « Commencer » ne doit plus nécessiter deux essais après
                            // un swipe : on force `delaysContentTouches = false` directement sur
                            // le vrai UIScrollView (le proxy global d'apparence n'est pas
                            // fiablement appliqué au ScrollView SwiftUI).
                            .background(ImmediateTouchScrollFixer())

                            // Espace de fin (hors cibles de snap) pour que la dernière carte
                            // puisse tout de même s'aligner en haut malgré des rangées un peu
                            // plus courtes qu'un plein écran.
                            Color.clear.frame(height: peekHeight)
                        }
                        // `.viewAligned` anchors to each card's real edges (one card per
                        // swipe, no overshoot), unlike `.paging` which advances by fixed
                        // viewport-sized steps and could drift past the intended card.
                        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                        .scrollPosition(id: $scrolledCardId)
                        .scrollDisabled(cards.count <= 1)
                        .onChange(of: scrolledCardId) { oldValue, newValue in
                            guard oldValue != nil, newValue != nil else { return }
                            if suppressNextSwipeCount {
                                suppressNextSwipeCount = false
                                return
                            }
                            // Légère vibration à chaque scroll (swipe utilisateur).
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            registerDiscountSwipe()
                        }
                    }
                    // Fondu d'entrée sans `scaleEffect` : la mise à l'échelle du conteneur
                    // perturbait le hit-testing du bouton « Commencer » pendant l'animation.
                    .opacity(cardAppeared ? 1 : 0)
                }
            }

            if showSwipeExplain {
                FirstOpenExplanation(
                    icon: "hand.point.up.left",
                    title: languageManager.text("explain.home.title"),
                    message: languageManager.text("explain.home.body"),
                    onDismiss: {
                        showSwipeExplain = false
                        TutorialFlags.markSeen(.homeSwipe)
                    }
                )
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .onAppear {
            loadCards()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                cardAppeared = true
            }
            maybeShowSwipeExplain()
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
                .font(.jakarta(size: 14, weight: .medium))
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
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .fixedSize(horizontal: true, vertical: false)
        .background(DS.surface, in: Capsule())
        .overlay { Capsule().strokeBorder(DS.hairline, lineWidth: 1) }
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

    private func maybeShowSwipeExplain() {
        guard HomeCardPresentation.style == .tiktok else { return }
        guard !TutorialFlags.seen(.homeSwipe) else { return }
        guard cards.count > 1 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            guard !TutorialFlags.seen(.homeSwipe) else { return }
            withAnimation(.easeIn(duration: 0.3)) {
                showSwipeExplain = true
            }
        }
    }

    /// Called when a course is dismissed after being opened from the feed: cycles it to the
    /// end of the deck (same "come back to it later" semantics as the Tinder/legacy skip)
    /// and scrolls to whichever course now takes its place, without counting it as a swipe.
    private func advancePast(courseId: String) {
        guard let index = cards.firstIndex(where: { $0.id == courseId }) else { return }
        let finished = cards.remove(at: index)
        cards.append(finished)
        let nextId = cards.indices.contains(index) ? cards[index].id : cards.first?.id
        guard nextId != scrolledCardId else { return }
        suppressNextSwipeCount = true
        withAnimation(.easeInOut(duration: 0.3)) {
            scrolledCardId = nextId
        }
    }

    private func loadCards() {
        cards = HomeDeckBuilder.deck(
            from: ContentCatalog.activeCourses,
            isCompleted: { progressManager.courseStatus(for: $0) == .completed }
        )
        scrolledCardId = cards.first?.id
        let preloadIds = cards.prefix(5).map(\.id)
        CourseImageMap.preloadImages(for: preloadIds)
    }

    private var allCompletedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.jakarta(size: 52, weight: .light))
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

// MARK: - Course card (contained image + panel, per the home mockup)

private struct TikTokCourseCard: View {
    let course: Course
    var language: AppLanguage = .french
    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)? = nil
    let onStart: () -> Void

    @State private var cachedImage: UIImage?
    @State private var startTrigger: Int = 0

    var body: some View {
        GeometryReader { geo in
            // The card sits near the TOP of its one-viewport row (not centered): this lifts
            // the current card a touch higher and, crucially, makes the bottom "peek" reveal
            // the START of the next card rather than empty space above it.
            let cardWidth = geo.size.width - DS.Space.m * 2
            let maxCardHeight = geo.size.height - DS.Space.s * 2
            // Illustration scales down a little on short screens so the whole card fits.
            let imageHeight = min(max(geo.size.height * 0.30, 170), 240)

            VStack(spacing: 0) {
                cardContent(imageHeight: imageHeight)
                    .frame(width: cardWidth)
                    .frame(maxHeight: maxCardHeight)
                    .padding(.top, DS.Space.s)
                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .onAppear {
            if cachedImage == nil {
                cachedImage = CourseImageMap.loadImage(for: course.id)
            }
        }
    }

    private func cardContent(imageHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            courseIllustration
                .frame(height: imageHeight)
                .frame(maxWidth: .infinity)
                .clipShape(.rect(cornerRadius: DS.Radius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1)
                }
                .overlay(alignment: .topTrailing) { favoriteButton }

            HStack(spacing: 8) {
                subjectPill
                Spacer(minLength: 0)
                readsPill
            }

            Text(course.title)
                .font(DS.title(.title3))
                .foregroundStyle(DS.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            boldText(accroche)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .lineSpacing(4)
                .lineLimit(6)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                startTrigger += 1
                onStart()
            } label: {
                HStack(spacing: 8) {
                    Text(AppLocalizable.string("home.start", language: language))
                    Image(systemName: "play.fill")
                        .font(.jakarta(size: 13, weight: .semibold))
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .sensoryFeedback(.impact(weight: .medium), trigger: startTrigger)
            .padding(.top, 2)
        }
        .padding(DS.Space.l)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
    }

    /// Phrase d'accroche affichée sous le titre. On privilégie le « hook » (cliffhanger) de
    /// la première page du cours (contenu v2), dans la langue courante ; sinon on retombe sur
    /// la description. Auparavant réservé au français, ce qui laissait les autres langues sur
    /// l'ancienne intro tronquée au lieu du cliffhanger.
    private var accroche: String {
        if let hook = CourseContentStore.content(courseId: course.id, language: language)?.hero?.hook,
           !hook.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return hook
        }
        return course.description
    }

    private var courseIllustration: some View {
        DS.surfaceMuted
            .overlay {
                if let cachedImage {
                    Color.clear
                        .overlay {
                            Image(uiImage: cachedImage)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                        .allowsHitTesting(false)
                } else {
                    ZStack {
                        DS.surfaceMuted
                        Image(systemName: course.subject.icon)
                            .font(.jakarta(size: 44, weight: .light))
                            .foregroundStyle(DS.accentSoft.opacity(0.5))
                    }
                }
            }
    }

    private var favoriteButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onToggleFavorite?()
        } label: {
            Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                .font(.jakarta(size: 15, weight: .semibold))
                .foregroundStyle(isFavorite ? DS.accent : DS.inkSecondary)
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial, in: Circle())
                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
        }
        .padding(12)
    }

    private var subjectPill: some View {
        HStack(spacing: 6) {
            Image(systemName: course.subject.icon)
                .font(.jakarta(size: 10, weight: .semibold))
            Text(course.subject.localizedShortName(language: language).uppercased())
                .font(DS.sans(.caption2, .bold))
                .tracking(1.0)
        }
        .foregroundStyle(DS.accentSoft)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(DS.accentTint, in: Capsule())
        .overlay { Capsule().strokeBorder(DS.accentSoft.opacity(0.2), lineWidth: 1) }
    }

    private var readsPill: some View {
        HStack(spacing: 5) {
            Image(systemName: "book.pages")
                .font(.jakarta(size: 10, weight: .medium))
            Text(String(format: AppLocalizable.string("course.reads", language: language), course.readsCountShort))
                .font(DS.sans(.caption2, .semibold))
        }
        .foregroundStyle(DS.inkTertiary)
        .fixedSize(horizontal: true, vertical: false)
    }

    private func boldText(_ input: String) -> Text {
        let parts = input.components(separatedBy: "**")
        var result = Text("")
        for (index, part) in parts.enumerated() {
            if index % 2 == 1 {
                result = result + Text(part).fontWeight(.semibold).foregroundColor(DS.inkSecondary)
            } else {
                result = result + Text(part)
            }
        }
        return result
    }
}
