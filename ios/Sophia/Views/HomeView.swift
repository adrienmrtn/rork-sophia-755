import SwiftUI

struct HomeView: View {
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    @Binding var autoSwipeCourseId: String?
    var onLockedTap: (() -> Void)? = nil
    @State private var cards: [Course] = []
    @State private var topCardOffset: CGSize = .zero
    @State private var topCardRotation: Double = 0
    @State private var cardAppeared: Bool = false

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
            cream.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                promptSection
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                if cards.isEmpty {
                    Spacer()
                    allCompletedView
                    Spacer()
                } else {
                    cardStack
                        .padding(.top, 18)
                        .opacity(cardAppeared ? 1 : 0)
                        .scaleEffect(cardAppeared ? 1 : 0.95)
                    Spacer(minLength: 8)
                    swipeHint
                        .padding(.bottom, 18)
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
            Text("Sophia")
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)

            Spacer()

            streakBadge
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 6) {
            Text("🔥")
                .font(.subheadline)
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

    private var promptSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Prêt à apprendre ?")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                Text("Swipe pour découvrir un cours")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(ink.opacity(0.5))
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
                    dailyDone: progressManager.hasCompletedCourseToday,
                    onStart: {
                        if progressManager.hasCompletedCourseToday {
                            onLockedTap?()
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
    var dailyDone: Bool = false
    let onStart: () -> Void
    @State private var cachedImage: UIImage?
    @State private var buttonTrigger: Int = 0
    @State private var bookmarked: Bool = false

    private let ink = Color.black
    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)
    private let depth: CGFloat = 6

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
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                } else {
                    ZStack {
                        pastel
                        Image(systemName: course.subject.icon)
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(ink.opacity(0.25))
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
                    bookmarked.toggle()
                } label: {
                    Image(systemName: bookmarked ? "bookmark.fill" : "bookmark")
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
        VStack(alignment: .leading, spacing: 12) {
            // Subject pill — black with icon + uppercase name
            HStack(spacing: 6) {
                Image(systemName: course.subject.icon)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
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
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            boldText(course.description)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink.opacity(0.85))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if dailyDone {
                dailyDoneBadge
                    .padding(.top, 4)
            } else {
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
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(pastel)
    }

    /// Badge replacing the "Commencer" button once the user has completed their free daily course.
    private var dailyDoneBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(.subheadline, weight: .heavy))
                .foregroundStyle(ink)
            Text("Cours du jour fait — reviens demain")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text("🔥")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.white, in: Capsule())
        .overlay { Capsule().strokeBorder(ink, lineWidth: 3) }
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
