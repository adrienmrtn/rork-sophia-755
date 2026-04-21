import SwiftUI

struct HomeView: View {
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    @Binding var autoSwipeCourseId: String?
    @State private var cards: [Course] = []
    @State private var topCardOffset: CGSize = .zero
    @State private var topCardRotation: Double = 0
    @State private var cardAppeared: Bool = false

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
        let filtered = CourseData.allCourses
            .filter { progressManager.courseStatus(for: $0.id) != .completed }
            .shuffled()
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
                    cardStack
                        .padding(.top, 16)
                        .opacity(cardAppeared ? 1 : 0)
                        .scaleEffect(cardAppeared ? 1 : 0.95)
                    Spacer()
                    swipeHint
                        .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            loadCards()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                cardAppeared = true
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
        HStack(alignment: .center) {
            Image("logo_white")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 28)

            Spacer()

            streakBadge
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 6) {
            Text("🔥")
                .font(.title3)
            Text("\(progressManager.streak)")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
            Text(progressManager.streak <= 1 ? "jour" : "jours")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
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
            }
            Spacer()
        }
    }

    private var cardStack: some View {
        ZStack {
            ForEach(Array(cards.prefix(3).enumerated().reversed()), id: \.element.id) { index, course in
                let isTop = index == 0
                FlashCard(
                    course: course,
                    onStart: { selectedCourse = course }
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
    let onStart: () -> Void
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
                    onStart()
                } label: {
                    HStack(spacing: 8) {
                        Text("Commencer")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                        Image(systemName: "play.fill")
                            .font(.caption)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SophiaTheme.emerald, in: .rect(cornerRadius: 14))
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
            .clipShape(.rect(cornerRadii: .init(topLeading: 24, topTrailing: 24)))
    }
}
