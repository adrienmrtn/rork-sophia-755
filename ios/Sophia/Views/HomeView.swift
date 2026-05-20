import SwiftUI

struct HomeView: View {
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    @Binding var autoSwipeCourseId: String?
    let isPremium: Bool
    let freemiumSubjects: Set<String>
    let onShowPaywallFromStart: () -> Void
    let onShowPaywallFromQuizBanner: () -> Void
    @State private var cards: [Course] = []
    @State private var topCardOffset: CGSize = .zero
    @State private var topCardRotation: Double = 0
    @State private var cardAppeared: Bool = false

    private var hasCompletedDailyCourse: Bool {
        !isPremium && progressManager.hasCompletedDailyFreeCourseToday
    }

    private var dailyBadgeText: String {
        hasCompletedDailyCourse ? "✓ Cours du jour fait — reviens demain 🔥" : "✓ 1 cours gratuit disponible aujourd'hui"
    }

    private var dailyBadgeBackground: Color {
        hasCompletedDailyCourse ? .white.opacity(0.08) : SophiaTheme.emerald.opacity(0.18)
    }

    private var dailyBadgeForeground: Color {
        hasCompletedDailyCourse ? .white.opacity(0.65) : SophiaTheme.emerald
    }

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
            }
            topCardOffset = .zero
            topCardRotation = 0
        }
    }

    private func loadCards() {
        var filtered = CourseData.allCourses
            .filter { progressManager.courseStatus(for: $0.id) != .completed }

        if !isPremium, !freemiumSubjects.isEmpty {
            filtered = filtered.filter { freemiumSubjects.contains($0.subject.rawValue) }
        }

        filtered.shuffle()
        cards = filtered
        let preloadIds = filtered.prefix(5).map(\.id)
        CourseImageMap.preloadImages(for: preloadIds)
    }

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                promptSection
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                Spacer()

                if cards.isEmpty {
                    allCompletedView
                    Spacer()
                } else {
                    if !isPremium {
                        dailyBadge
                            .padding(.top, 12)
                            .padding(.horizontal, 20)
                    }

                    cardStack
                        .padding(.top, 16)
                        .opacity(cardAppeared ? 1 : 0)
                        .scaleEffect(cardAppeared ? 1 : 0.95)
                    Spacer()
                    swipeHint
                        .padding(.bottom, 24)

                    if hasCompletedDailyCourse {
                        quizBanner
                            .padding(.horizontal, 20)
                            .padding(.bottom, 18)
                    }
                }
            }
        }
        .onAppear {
            loadCards()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                cardAppeared = true
            }
        }
        .onChange(of: isPremium) { _, _ in
            loadCards()
        }
        .onChange(of: freemiumSubjects) { _, _ in
            loadCards()
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
        HStack(alignment: .center) {
            Image("logo_white")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 28)

            Spacer()

            if progressManager.streak > 0 {
                streakBadge
            }
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 6) {
            Text("🔥")
                .font(.title3)
            Text("Jour \(progressManager.streak)")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            if isPremium && progressManager.shieldCount > 0 {
                Text("🛡️")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white.opacity(0.08), in: Capsule())
    }

    private var promptSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Prêt à apprendre ?")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Text("Swipe pour découvrir un cours")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                if progressManager.didBreakStreakToday {
                    Text("Ta série est brisée. Recommence dès aujourd'hui.")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(SophiaTheme.errorRed.opacity(0.12), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(SophiaTheme.errorRed.opacity(0.35), lineWidth: 1)
                        )
                        .padding(.top, 6)
                }

                if isPremium && progressManager.didUseShieldToday, let value = progressManager.shieldProtectedStreakValue {
                    Text("Ton bouclier a protégé ta série de \(value) jours")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.10), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                        )
                        .padding(.top, 6)
                }
            }
            Spacer()
        }
    }

    private var cardStack: some View {
        ZStack {
            ForEach(Array(cards.prefix(3).enumerated().reversed()), id: \.element.id) { index, course in
                let isTop = index == 0
                let isSubjectLocked = !isPremium && !freemiumSubjects.isEmpty && !freemiumSubjects.contains(course.subject.rawValue)
                let isStartLocked = hasCompletedDailyCourse || isSubjectLocked
                FlashCard(
                    course: course,
                    isStartLocked: isStartLocked,
                    onStart: { selectedCourse = course },
                    onLockedStart: {
                        let g = UIImpactFeedbackGenerator(style: .medium)
                        g.impactOccurred()
                        onShowPaywallFromStart()
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
        .frame(height: 480)
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
                    .font(.system(.caption, design: .rounded, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.3))

            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: 6, height: 6)

            HStack(spacing: 6) {
                Text("Passer")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                Image(systemName: "arrow.right")
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.3))
        }
    }

    private var dailyBadge: some View {
        HStack {
            Text(dailyBadgeText)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(dailyBadgeForeground)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(dailyBadgeBackground, in: Capsule())
            Spacer()
        }
    }

    private var quizBanner: some View {
        Button {
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
            onShowPaywallFromQuizBanner()
        } label: {
            HStack(spacing: 10) {
                Text("🔒 Accède aux quiz — essai gratuit →")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.white.opacity(0.06), in: .rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var allCompletedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(SophiaTheme.emerald)
            Text("Bravo !")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text("Tu as terminé tous les cours disponibles.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

struct FlashCard: View {
    let course: Course
    let isStartLocked: Bool
    let onStart: () -> Void
    let onLockedStart: () -> Void
    @State private var cachedImage: UIImage?
    @State private var buttonTrigger: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            courseIllustration

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: course.subject.icon)
                        .font(.caption)
                        .foregroundStyle(.white)
                    Text(course.subject.shortName.uppercased())
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(course.subject.color.opacity(0.85), in: Capsule())

                Text(course.title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                boldText(course.description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(2)

                Button {
                    buttonTrigger += 1
                    if isStartLocked {
                        onLockedStart()
                    } else {
                        onStart()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(isStartLocked ? "🔒 Commencer — essai gratuit" : "Commencer")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                        Image(systemName: isStartLocked ? "lock.fill" : "play.fill")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        isStartLocked ? .white.opacity(0.10) : SophiaTheme.emerald,
                        in: .rect(cornerRadius: 14)
                    )
                    .opacity(isStartLocked ? 0.7 : 1.0)
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: buttonTrigger)
            }
            .padding(20)
            .background(SophiaTheme.cardBackground)
            .clipShape(.rect(cornerRadii: .init(bottomLeading: 24, bottomTrailing: 24)))
        }
        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
        .onAppear {
            if cachedImage == nil {
                cachedImage = CourseImageMap.loadImage(for: course.id)
            }
        }
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

    private var courseIllustration: some View {
        Color(.secondarySystemBackground)
            .frame(height: 260)
            .overlay {
                if let uiImage = cachedImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                } else {
                    ZStack {
                        course.subject.color.opacity(0.25)
                        LinearGradient(
                            colors: [course.subject.color.opacity(0.5), course.subject.color.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: course.subject.icon)
                            .font(.system(size: 56, weight: .light))
                            .foregroundStyle(.white.opacity(0.2))
                            .rotationEffect(.degrees(-12))
                            .offset(x: 50, y: -10)
                    }
                }
            }
            .overlay(alignment: .bottomLeading) {
                EmptyView()
            }
            .clipShape(.rect(cornerRadii: .init(topLeading: 24, topTrailing: 24)))
    }
}
