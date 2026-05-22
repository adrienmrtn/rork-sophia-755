import SwiftUI

struct ProfileView: View {
    let progressManager: ProgressManager
    let store: StoreViewModel
    @Binding var selectedCourse: Course?
    var onShowPaywall: (() -> Void)? = nil
    var onResetOnboarding: (() -> Void)? = nil

    @State private var showSettings: Bool = false
    @State private var showFavorites: Bool = false
    @State private var showAllQuizzes: Bool = false
    @State private var hapticTrigger: Int = 0
    @State private var appeared: Bool = false

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    /// Subjects unlocked for the current user (based on onboarding interests for freemium).
    private var unlockedSubjects: Set<Subject> {
        FreemiumGate.unlockedSubjects(isPremium: store.isPremium)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        titleBar
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                        streakHero
                            .padding(.horizontal, 20)

                        favoritesShortcut
                            .padding(.horizontal, 20)

                        quizSection
                            .padding(.horizontal, 20)

                        progressionSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                }
            }
            .navigationBarHidden(true)
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView(
                    progressManager: progressManager,
                    store: store,
                    onShowPaywall: onShowPaywall,
                    onResetOnboarding: onResetOnboarding,
                    onDismiss: { showSettings = false }
                )
            }
            .fullScreenCover(isPresented: $showFavorites) {
                FavoritesSheet(
                    progressManager: progressManager,
                    selectedCourse: $selectedCourse,
                    onDismiss: { showFavorites = false }
                )
            }
            .fullScreenCover(isPresented: $showAllQuizzes) {
                AllQuizzesView(
                    progressManager: progressManager,
                    selectedCourse: $selectedCourse,
                    onDismiss: { showAllQuizzes = false }
                )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
    }

    // MARK: - Title bar (custom title + gear)

    private var titleBar: some View {
        HStack(alignment: .center) {
            Text("Profil")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)

            Spacer()

            Button {
                hapticTrigger += 1
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(ink)
                    .frame(width: 46, height: 46)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
            }
            .buttonStyle(BrutalIconButtonStyle())
        }
    }

    // MARK: - Streak hero

    private var streakHero: some View {
        let streak = progressManager.streak
        let peach = BrutalPalette.pastel(for: .histoire)

        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(ink)
                .offset(y: 6)

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🔥")
                            .font(.system(size: 56))
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(streak)")
                                .font(.system(size: 64, weight: .heavy, design: .rounded))
                                .foregroundStyle(ink)
                                .contentTransition(.numericText())
                            Text(streak <= 1 ? "JOUR" : "JOURS")
                                .font(.system(.headline, design: .rounded, weight: .heavy))
                                .foregroundStyle(ink)
                                .tracking(1)
                        }
                        Text(streakSubtitle(streak))
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.65))
                    }
                    Spacer()
                }

                weekStrip
            }
            .padding(20)
            .background(peach)
            .clipShape(.rect(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(ink, lineWidth: 3)
            }
        }
        .padding(.bottom, 6)
    }

    private func streakSubtitle(_ s: Int) -> String {
        switch s {
        case 0: "Lis un cours pour démarrer !"
        case 1...2: "Tu as commencé, continue !"
        case 3...6: "Belle régularité 👏"
        default: "Tu es en feu 🔥"
        }
    }

    private var weekStrip: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayLetters = ["L", "M", "M", "J", "V", "S", "D"]
        // Build last 7 days ending today; Monday-first.
        let weekday = calendar.component(.weekday, from: today) // 1 = Sunday
        let mondayOffset = ((weekday + 5) % 7)
        let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) ?? today

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let lastActive = progressManager.progress.lastActiveDate
        let streak = progressManager.streak

        return HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { i in
                let date = calendar.date(byAdding: .day, value: i, to: monday) ?? today
                let isToday = calendar.isDate(date, inSameDayAs: today)
                let isFuture = date > today
                let dateStr = fmt.string(from: date)

                // A day is "done" if it's within the current streak window ending on lastActive.
                let isDone: Bool = {
                    guard let last = lastActive,
                          let lastDate = fmt.date(from: last) else { return false }
                    let daysFromLast = calendar.dateComponents([.day], from: date, to: lastDate).day ?? 999
                    if isFuture { return false }
                    return dateStr <= last && daysFromLast >= 0 && daysFromLast < streak
                }()

                VStack(spacing: 6) {
                    Text(dayLetters[i])
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink.opacity(isFuture ? 0.25 : 0.55))
                    ZStack {
                        Circle()
                            .fill(isDone ? ink : Color.white)
                            .overlay { Circle().strokeBorder(ink, lineWidth: 2) }
                        if isDone {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundStyle(.white)
                        } else if isToday {
                            Circle().fill(ink).frame(width: 6, height: 6)
                        }
                    }
                    .frame(width: 30, height: 30)
                    .opacity(isFuture ? 0.4 : 1)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Favorites shortcut

    private var favoritesShortcut: some View {
        Button {
            hapticTrigger += 1
            showFavorites = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(BrutalPalette.pink)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(ink, lineWidth: 2)
                        }
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(ink)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Mes favoris")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                    Text("\(progressManager.favoriteCourses.count) cours sauvegardés")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.55))
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .buttonStyle(BrutalCardButtonStyle(depth: 4))
        .brutalCard()
    }

    // MARK: - Quiz section

    private var quizSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MES QUIZ RÉCENTS")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.55))
                    .tracking(1.2)
                Spacer()
                if store.isPremium && !progressManager.recentQuizzes.isEmpty {
                    Button {
                        hapticTrigger += 1
                        showAllQuizzes = true
                    } label: {
                        Text("Voir plus →")
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink)
                    }
                }
            }
            .padding(.horizontal, 8)

            if !store.isPremium {
                quizLockedBanner
            } else if progressManager.recentQuizzes.isEmpty {
                emptyQuizzesCard
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(progressManager.recentQuizzes.prefix(3).enumerated()), id: \.element.course.id) { idx, item in
                        QuizRowView(
                            course: item.course,
                            score: item.score,
                            total: item.totalQuestions,
                            onRetry: {
                                hapticTrigger += 1
                                selectedCourse = item.course
                            }
                        )
                        if idx < min(2, progressManager.recentQuizzes.count - 1) {
                            Rectangle().fill(ink).frame(height: 2)
                        }
                    }
                }
                .brutalCard()
            }
        }
    }

    private var quizLockedBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(BrutalPalette.pink)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(ink, lineWidth: 2)
                        }
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(ink)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Quiz verrouillés")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                    Text("Disponibles avec l'essai gratuit — 3 jours offerts")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            Button {
                hapticTrigger += 1
                onShowPaywall?()
            } label: {
                HStack(spacing: 8) {
                    Text("Débloquer mes quiz")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .heavy))
                }
                .foregroundStyle(ink)
            }
            .buttonStyle(BrutalPinkButtonCompact())
        }
        .padding(16)
        .brutalCard()
    }

    private var emptyQuizzesCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(BrutalPalette.pastel(for: .sciences))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(ink, lineWidth: 2)
                    }
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(ink)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("Pas encore de quiz")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                Text("Termine un cours pour passer ton premier quiz.")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .brutalCard()
    }

    // MARK: - Progression by subject

    private var progressionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PROGRESSION PAR THÈME")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.55))
                    .tracking(1.2)
                Spacer()
            }
            .padding(.horizontal, 8)

            VStack(spacing: 14) {
                ForEach(Subject.allCases, id: \.self) { subject in
                    let unlocked = unlockedSubjects.contains(subject)
                    SubjectProgressCard(
                        subject: subject,
                        xp: progressManager.xp(for: subject),
                        unlocked: unlocked,
                        onUnlock: {
                            hapticTrigger += 1
                            onShowPaywall?()
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Subject progress card

private struct SubjectProgressCard: View {
    let subject: Subject
    let xp: Int
    let unlocked: Bool
    let onUnlock: () -> Void

    private let ink = BrutalPalette.ink

    /// XP-based tiers. NIV 1: 0-49, 2: 50-149, 3: 150-349, 4: 350-699, 5: 700+.
    private static let tiers: [(level: Int, lower: Int, upper: Int)] = ProgressManager.subjectXPTiers

    private var currentTier: (level: Int, lower: Int, upper: Int) {
        Self.tiers.last(where: { xp >= $0.lower }) ?? Self.tiers[0]
    }

    private var progressInLevel: Double {
        let tier = currentTier
        if tier.level == 5 { return 1.0 }
        let span = max(1, tier.upper - tier.lower)
        let inLevel = max(0, xp - tier.lower)
        return min(1.0, Double(inLevel) / Double(span))
    }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ink)
                .offset(y: 4)

            HStack(spacing: 14) {
                // Subject icon badge
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(unlocked ? BrutalPalette.pastel(for: subject) : Color(white: 0.92))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(ink, lineWidth: 2)
                        }
                    Image(systemName: unlocked ? subject.icon : "lock.fill")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(unlocked ? ink : ink.opacity(0.55))
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(subject.shortName)
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(unlocked ? ink : ink.opacity(0.45))
                        if unlocked {
                            Text("NIV. \(currentTier.level)")
                                .font(.system(.caption2, design: .rounded, weight: .heavy))
                                .foregroundStyle(.white)
                                .tracking(0.6)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(ink, in: Capsule())
                        }
                        Spacer(minLength: 0)
                    }

                    if unlocked {
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(white: 0.94))
                                    .overlay { Capsule().strokeBorder(ink, lineWidth: 1.5) }
                                Capsule()
                                    .fill(BrutalPalette.pastel(for: subject))
                                    .overlay { Capsule().strokeBorder(ink, lineWidth: 1.5) }
                                    .frame(width: max(10, geo.size.width * progressInLevel))
                            }
                        }
                        .frame(height: 10)

                        Text(progressLabel)
                            .font(.system(.caption2, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.55))
                    } else {
                        Text("Débloque avec l'essai gratuit")
                            .font(.system(.caption, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(unlocked ? Color.white : Color(white: 0.97))
            .clipShape(.rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(ink, lineWidth: 2.5)
            }
            .opacity(unlocked ? 1 : 0.85)
        }
        .padding(.bottom, 4)
        .onTapGesture {
            if !unlocked { onUnlock() }
        }
    }

    private var progressLabel: String {
        let tier = currentTier
        if tier.level == 5 { return "\(xp) XP · niveau max" }
        let toNext = max(0, tier.upper - xp)
        return "\(xp) XP · \(toNext) avant niv. \(tier.level + 1)"
    }
}

// MARK: - Quiz row

private struct QuizRowView: View {
    let course: Course
    let score: Int
    let total: Int
    let onRetry: () -> Void

    private let ink = BrutalPalette.ink

    /// Score on /5 scale.
    private var fiveScore: Int {
        guard total > 0 else { return 0 }
        return max(0, min(5, Int(round(Double(score) / Double(total) * 5))))
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(course.title)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < fiveScore ? "star.fill" : "star")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(i < fiveScore ? ink : ink.opacity(0.3))
                    }
                    Text("\(fiveScore)/5")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink.opacity(0.55))
                        .padding(.leading, 4)
                }
            }

            Spacer(minLength: 8)

            Button(action: onRetry) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .heavy))
                    Text("Refaire")
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                }
                .foregroundStyle(ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(BrutalPalette.pastel(for: course.subject), in: Capsule())
                .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
            }
            .buttonStyle(BrutalIconButtonStyle(depth: 2))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - All quizzes screen

struct AllQuizzesView: View {
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    var onDismiss: () -> Void
    @State private var hapticTrigger: Int = 0

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Tous mes quiz")
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink)
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundStyle(ink)
                                .frame(width: 38, height: 38)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    Color.clear.frame(height: 0)
                    Group {

                    if progressManager.recentQuizzes.isEmpty {
                        Text("Aucun quiz pour le moment.")
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.55))
                            .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(progressManager.recentQuizzes.enumerated()), id: \.element.course.id) { idx, item in
                                QuizRowView(
                                    course: item.course,
                                    score: item.score,
                                    total: item.totalQuestions,
                                    onRetry: {
                                        hapticTrigger += 1
                                        selectedCourse = item.course
                                    }
                                )
                                if idx < progressManager.recentQuizzes.count - 1 {
                                    Rectangle().fill(ink).frame(height: 2)
                                }
                            }
                        }
                        .brutalCard()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    }
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
    }
}

// MARK: - Favorites sheet wrapper

private struct FavoritesSheet: View {
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    var onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            FavoritesView(
                progressManager: progressManager,
                selectedCourse: $selectedCourse
            )
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .frame(width: 38, height: 38)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2.5) }
            }
            .padding(.trailing, 20)
            .padding(.top, 10)
        }
        .onChange(of: selectedCourse) { _, newValue in
            if newValue != nil { onDismiss() }
        }
    }
}

// MARK: - Shared button styles & card modifier

struct BrutalIconButtonStyle: ButtonStyle {
    var depth: CGFloat = 2
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct BrutalPinkButtonCompact: ButtonStyle {
    var depth: CGFloat = 4
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                ZStack(alignment: .top) {
                    Capsule()
                        .fill(BrutalPalette.ink)
                        .offset(y: depth)
                    Capsule()
                        .fill(BrutalPalette.pink)
                        .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2.5) }
                        .offset(y: pressed ? depth : 0)
                }
            )
            .padding(.bottom, depth)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: pressed)
    }
}

/// Brutalist card modifier (white bg, black border, solid offset shadow).
struct BrutalProfileCardModifier: ViewModifier {
    let ink = BrutalPalette.ink
    var depth: CGFloat = 4

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ink)
                .offset(y: depth)

            content
                .background(Color.white)
                .clipShape(.rect(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(ink, lineWidth: 2.5)
                }
        }
        .padding(.bottom, depth)
    }
}

extension View {
    /// Brutalist card used across the Profile screen.
    func brutalCard() -> some View {
        modifier(BrutalProfileCardModifier())
    }
}
