import SwiftUI

struct HomeView: View {
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
    private let streakOrange = Color(red: 1.0, green: 0.45, blue: 0.10)

    private func performAutoSwipe() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
        withAnimation(.snappy(duration: 0.45)) {
            topCardOffset = CGSize(width: -500, height: 0)
            topCardRotation = -20
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            if !cards.isEmpty {
                let removed = cards.removeFirst()
                cards.append(removed)
                cards = DeckBalancer.afterSwipe(cards, unlockedSubjects: unlockedSubjects, isPremium: isPremium)
            }
            topCardOffset = .zero
            topCardRotation = 0
        }
    }

    private func loadCards() {
        let filtered = CourseData.allCourses
            .filter { progressManager.courseStatus(for: $0.id) != .completed }
        cards = DeckBalancer.balancedDeck(
            courses: filtered,
            unlockedSubjects: unlockedSubjects,
            isPremium: isPremium
        )
        let preloadIds = cards.prefix(5).map(\.id)
        CourseImageMap.preloadImages(for: preloadIds)
    }

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

                if cards.isEmpty {
                    Spacer()
                    allCompletedView
                    Spacer()
                } else {
                    Spacer(minLength: 0)
                    cardStack
                        .opacity(cardAppeared ? 1 : 0)
                        .scaleEffect(cardAppeared ? 1 : 0.95)
                    Spacer(minLength: 0)
                    swipeHint
                        .padding(.bottom, 18)
                }
            }
        }
        .onAppear {
            loadCards()
            discountShimmerActive = !isPremium && discountManager.isActive
            if discountShimmerActive {
                ShimmerAnimation.runLoop(offset: $discountShimmer) { discountShimmerActive }
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
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
                performAutoSwipe()
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Sophia")
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)

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
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.impactOccurred()
            onShowDiscountPaywall?()
        } label: {
            HStack(spacing: 6) {
                AnimatedFlameBadge(size: 14, showGlow: false)
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
            Text(progressManager.streak <= 1 ? "JOUR" : "JOURS")
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .tracking(0.5)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white, in: Capsule())
        .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
    }


    private var cardStack: some View {
        ZStack {
            ForEach(Array(cards.prefix(3).enumerated().reversed()), id: \.element.id) { index, course in
                let isTop = index == 0
                let subjectLocked = !isPremium && !unlockedSubjects.contains(course.subject)
                FlashCard(
                    course: course,
                    isFavorite: progressManager.isFavorite(course.id),
                    isSubjectLocked: subjectLocked,
                    onToggleFavorite: {
                        progressManager.toggleFavorite(course.id)
                    },
                    onStart: {
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
                )
                .offset(
                    x: isTop ? topCardOffset.width : 0,
                    y: isTop ? topCardOffset.height : CGFloat(index) * 8
                )
                .scaleEffect(isTop ? 1.0 : 1.0 - CGFloat(index) * 0.04)
                .rotationEffect(.degrees(isTop ? topCardRotation : 0))
                .zIndex(Double(3 - index))
                .gesture(isTop ? dragGesture : nil)
                .animation(.snappy(duration: 0.3), value: topCardOffset)
            }
        }
        .frame(height: 520)
        .padding(.horizontal, 20)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                topCardOffset = value.translation
                topCardRotation = Double(value.translation.width / 25)
            }
            .onEnded { value in
                let threshold: CGFloat = 120
                let velocity = value.velocity.width

                if abs(value.translation.width) > threshold || abs(velocity) > 800 {
                    if !isPremium && !discountManager.hasBeenTriggered {
                        discountManager.triggerIfNeeded()
                        onShowDiscountPaywall?()
                    }
                    let direction: CGFloat = value.translation.width > 0 ? 1 : -1
                    let g = UIImpactFeedbackGenerator(style: .light)
                    g.impactOccurred()
                    withAnimation(.snappy(duration: 0.35)) {
                        topCardOffset = CGSize(width: direction * 500, height: value.translation.height)
                        topCardRotation = Double(direction * 20)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        if !cards.isEmpty {
                            let removed = cards.removeFirst()
                            cards.append(removed)
                            cards = DeckBalancer.afterSwipe(cards, unlockedSubjects: unlockedSubjects, isPremium: isPremium)
                        }
                        topCardOffset = .zero
                        topCardRotation = 0
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        topCardOffset = .zero
                        topCardRotation = 0
                    }
                }
            }
    }

    private var swipeHint: some View {
        HStack(spacing: 24) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left")
                    .font(.caption)
                Text("Passer")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(ink.opacity(0.35))

            Circle()
                .fill(ink.opacity(0.25))
                .frame(width: 6, height: 6)

            HStack(spacing: 6) {
                Text("Passer")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.caption)
            }
            .foregroundStyle(ink.opacity(0.55))
        }
    }


    private var allCompletedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(ink)
            Text("Bravo !")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
            Text("Tu as terminé tous les cours disponibles.")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(ink.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

struct FlashCard: View {
    let course: Course
    var isFavorite: Bool = false
    var isSubjectLocked: Bool = false
    var onToggleFavorite: (() -> Void)? = nil
    let onStart: () -> Void
    @State private var cachedImage: UIImage?
    @State private var buttonTrigger: Int = 0

    private let ink = Color.black
    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)
    private let depth: CGFloat = 2

    /// Pastel tint for the subject — mixes the subject color with white for a soft brutalist panel.
    private var pastel: Color {
        switch course.subject {
        case .histoire: return Color(red: 1.0, green: 0.86, blue: 0.62)        // peach
        case .sciences: return Color(red: 0.70, green: 0.95, blue: 0.80)        // mint
        case .litterature: return Color(red: 1.0, green: 0.78, blue: 0.78)      // soft red
        case .art: return Color(red: 0.66, green: 0.92, blue: 0.96)             // cyan (matches ref)
        case .mythologie: return Color(red: 0.82, green: 0.78, blue: 1.0)       // lavender
        case .comprendreLeMonde: return Color(red: 0.74, green: 0.90, blue: 1.0) // sky
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Solid black offset shadow plate (Duolingo / neo-brutalist)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(ink)
                .offset(y: depth)

            VStack(spacing: 0) {
                courseIllustration
                bottomPanel
            }
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 28))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(ink, lineWidth: 3)
            }
        }
        .onAppear {
            if cachedImage == nil {
                cachedImage = CourseImageMap.loadImage(for: course.id)
            }
        }
    }

    private var courseIllustration: some View {
        Color(.secondarySystemBackground)
            .frame(height: 240)
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
                            .font(.system(size: 64))
                    }
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(ink)
                    .frame(height: 3)
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    let g = UIImpactFeedbackGenerator(style: .light)
                    g.impactOccurred()
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
                        Text("Verrouillé")
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
        VStack(alignment: .leading, spacing: 12) {
            // Subject pill — black with icon + uppercase name
            HStack(spacing: 6) {
                Text(course.subject.emoji)
                    .font(.system(size: 16))
                Text(course.subject.shortName.uppercased())
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
                .lineLimit(2, reservesSpace: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            boldText(course.description)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.85))
                .lineLimit(3, reservesSpace: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                buttonTrigger += 1
                onStart()
            } label: {
                HStack(spacing: 8) {
                    Text("Commencer")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                    Image(systemName: "play.fill")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(BrutalistButtonStyle(fill: pink))
            .sensoryFeedback(.impact(weight: .medium), trigger: buttonTrigger)
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(pastel)
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

/// Neo-brutalist 3D button: solid black offset plate behind a colored capsule.
private struct BrutalistButtonStyle: ButtonStyle {
    let fill: Color
    private let depth: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Capsule().fill(fill)
                    .overlay { Capsule().strokeBorder(.black, lineWidth: 3) }
            )
            .offset(y: configuration.isPressed ? depth : 0)
            .background(
                Capsule().fill(Color.black).offset(y: depth)
            )
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
            .padding(.bottom, depth)
    }
}
