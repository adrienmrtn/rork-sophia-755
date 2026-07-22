import SwiftUI

struct ProfileView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth
    let progressManager: ProgressManager
    let store: StoreViewModel
    @Binding var selectedCourse: Course?
    var onShowPaywall: (() -> Void)? = nil
    var onResetOnboarding: (() -> Void)? = nil

    @State private var showSettings: Bool = false
    @State private var showFavorites: Bool = false
    @State private var showAllQuizzes: Bool = false
    @State private var showPendingGlobalRankUp: Bool = false
    @State private var showEditHandle: Bool = false
    @State private var hapticTrigger: Int = 0
    @State private var appeared: Bool = false
    @Bindable private var social = SocialService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                DS.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        titleBar
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                        identityHeader
                            .padding(.horizontal, 20)

                        statsSection
                            .padding(.horizontal, 20)

                        FriendsLeaderboardSection(social: social)
                            .padding(.horizontal, 20)

                        subjectLevelsSection
                            .padding(.horizontal, 20)

                        favoritesShortcut
                            .padding(.horizontal, 20)

                        quizSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                }
                .scrollIndicators(.hidden)
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
            .fullScreenCover(isPresented: $showPendingGlobalRankUp) {
                if let pending = progressManager.pendingGlobalRankUp() {
                    GlobalRankUpCelebrationView(
                        previousRank: pending.previous,
                        newRank: pending.new,
                        newLevel: pending.newLevel,
                        onContinue: {
                            progressManager.clearPendingGlobalRankUp()
                            showPendingGlobalRankUp = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showEditHandle) {
                if let handle = social.myHandle {
                    EditHandleSheet(currentHandle: handle) { _ in
                        Task { await social.refreshAll() }
                    }
                    .presentationDetents([.medium])
                }
            }
        }
        .task(id: auth.isSignedIn) {
            if auth.isSignedIn {
                await social.refreshAll()
            } else {
                social.clearLocalState()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
            if progressManager.pendingGlobalRankUp() != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if !showSettings && !showFavorites && !showAllQuizzes {
                        showPendingGlobalRankUp = true
                    }
                }
            }
        }
    }

    // MARK: - Title bar

    private var titleBar: some View {
        HStack(alignment: .center) {
            Text(languageManager.text("profile.title"))
                .font(DS.title(.largeTitle, .semibold))
                .foregroundStyle(DS.ink)

            Spacer()

            Button {
                hapticTrigger += 1
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.jakarta(size: 17, weight: .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 44, height: 44)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }
            .buttonStyle(ProfileCardPress())
        }
    }

    // MARK: - Identity header

    private var nickname: String {
        let interests = OnboardingViewModel.userInterestKeys()
        let keys = Subject.allCases.map(\.storageKey).filter { interests.contains($0) }
        guard let first = keys.first else {
            return languageManager.text("onboarding.program.nickname.default")
        }
        return languageManager.text("onboarding.program.nickname.\(first)")
    }

    private var identityHeader: some View {
        let p = progressManager.globalLevelProgress

        return VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                GlobalRankRing(progress: p, size: 96)

                VStack(alignment: .leading, spacing: 6) {
                    Text(p.rank.localizedName(language: languageManager.current).uppercased())
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(DS.accentSoft)
                        .tracking(1.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(nickname)
                        .font(DS.title(.title2, .semibold))
                        .foregroundStyle(DS.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)

                    if auth.isSignedIn, let handle = social.myHandle {
                        Button {
                            hapticTrigger += 1
                            showEditHandle = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("@\(handle)")
                                    .font(DS.sans(.subheadline, .semibold))
                                    .foregroundStyle(DS.accentSoft)
                                Image(systemName: "pencil")
                                    .font(.jakarta(size: 11, weight: .semibold))
                                    .foregroundStyle(DS.inkTertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Text(String(format: languageManager.text("common.levelShort"), p.level))
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.inkSecondary)
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 6) {
                CalmProgressBar(fraction: p.progressToNextRank)
                HStack {
                    Text(languageManager.text("globalRank.title"))
                        .font(DS.sans(.caption2, .medium))
                        .foregroundStyle(DS.inkTertiary)
                    Spacer()
                    Text("\(Int(p.progressToNextRank * 100))%")
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(DS.inkSecondary)
                        .monospacedDigit()
                }
            }
        }
        .dsCard()
    }

    // MARK: - Stats

    private var completedCoursesCount: Int {
        ContentCatalog.activeCourses.filter { progressManager.courseStatus(for: $0.id) == .completed }.count
    }

    private var statsSection: some View {
        let stats = progressManager.quizStatsSummary

        return VStack(spacing: 14) {
            streakCard

            HStack(spacing: 14) {
                statTile(
                    icon: "checkmark.circle",
                    value: "\(completedCoursesCount)",
                    label: languageManager.text("profile.stats.coursesDone")
                )
                statTile(
                    icon: "target",
                    value: "\(stats.successPercent)%",
                    label: languageManager.text("cards.successRate")
                )
            }
        }
    }

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.jakarta(size: 22, weight: .medium))
                    .foregroundStyle(DS.accentSoft)
                Text("\(progressManager.streak)")
                    .font(DS.title(.largeTitle, .semibold))
                    .foregroundStyle(DS.ink)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                Text(progressManager.streak <= 1 ? languageManager.text("common.streak.day") : languageManager.text("common.streak.days"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.inkSecondary)
                Spacer()
            }
            weekStrip
        }
        .dsCard()
    }

    private func statTile(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.jakarta(size: 16, weight: .medium))
                .foregroundStyle(DS.accentSoft)
                .frame(width: 38, height: 38)
                .background(DS.accentTint, in: Circle())
            Text(value)
                .font(DS.title(.title, .semibold))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
            Text(label)
                .font(DS.sans(.caption, .medium))
                .foregroundStyle(DS.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .dsCard(padding: 16)
    }

    private var weekStrip: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayLetters = ["L", "M", "M", "J", "V", "S", "D"]
        let weekday = calendar.component(.weekday, from: today)
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

                let isDone: Bool = {
                    guard let last = lastActive,
                          let lastDate = fmt.date(from: last) else { return false }
                    let daysFromLast = calendar.dateComponents([.day], from: date, to: lastDate).day ?? 999
                    if isFuture { return false }
                    return dateStr <= last && daysFromLast >= 0 && daysFromLast < streak
                }()

                VStack(spacing: 6) {
                    Text(dayLetters[i])
                        .font(DS.sans(.caption2, .medium))
                        .foregroundStyle(DS.inkTertiary)
                    ZStack {
                        if isDone {
                            Circle().fill(DS.accent)
                            Image(systemName: "checkmark")
                                .font(.jakarta(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        } else if isToday {
                            Circle().fill(DS.surface)
                            Circle().strokeBorder(DS.accentSoft, lineWidth: 2)
                        } else {
                            Circle().fill(DS.surfaceMuted)
                        }
                    }
                    .frame(width: 30, height: 30)
                    .opacity(isFuture ? 0.5 : 1)
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
                Image(systemName: "bookmark.fill")
                    .font(.jakarta(size: 16, weight: .medium))
                    .foregroundStyle(DS.accentSoft)
                    .frame(width: 40, height: 40)
                    .background(DS.accentTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(languageManager.text("profile.favorites"))
                        .font(DS.title(.headline, .semibold))
                        .foregroundStyle(DS.ink)
                    Text(String(format: languageManager.text("profile.favorites.count"), progressManager.favoriteCourses.count))
                        .font(DS.sans(.caption, .medium))
                        .foregroundStyle(DS.inkSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.jakarta(size: 13, weight: .semibold))
                    .foregroundStyle(DS.inkTertiary)
            }
            .dsCard(padding: 14)
        }
        .buttonStyle(ProfileCardPress())
    }

    // MARK: - Quiz section

    private var quizSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(languageManager.text("profile.quiz.recent").uppercased())
                    .font(DS.sans(.caption2, .semibold))
                    .foregroundStyle(DS.inkTertiary)
                    .tracking(1.2)
                Spacer()
                if store.isPremium && !progressManager.recentQuizzes.isEmpty {
                    Button {
                        hapticTrigger += 1
                        showAllQuizzes = true
                    } label: {
                        Text(languageManager.text("common.seeMoreArrow"))
                            .font(DS.sans(.subheadline, .medium))
                            .foregroundStyle(DS.accentSoft)
                    }
                }
            }
            .padding(.horizontal, 4)

            if progressManager.recentQuizzes.isEmpty {
                emptyQuizzesCard
            } else if store.isPremium {
                VStack(spacing: 0) {
                    ForEach(Array(progressManager.recentQuizzes.prefix(3).enumerated()), id: \.element.course.id) { idx, item in
                        QuizRowView(
                            course: item.course,
                            score: item.score,
                            total: item.totalPoints,
                            onRetry: {
                                hapticTrigger += 1
                                selectedCourse = item.course
                            }
                        )
                        if idx < min(2, progressManager.recentQuizzes.count - 1) {
                            Rectangle().fill(DS.hairline).frame(height: 1)
                        }
                    }
                }
                .dsCard(padding: 0)
            } else {
                emptyQuizzesCard
            }
        }
    }

    private var emptyQuizzesCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "questionmark.circle")
                .font(.jakarta(size: 16, weight: .medium))
                .foregroundStyle(DS.accentSoft)
                .frame(width: 40, height: 40)
                .background(DS.accentTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(languageManager.text("profile.quiz.emptyTitle"))
                    .font(DS.title(.headline, .semibold))
                    .foregroundStyle(DS.ink)
                Text(languageManager.text("profile.quiz.emptySubtitle"))
                    .font(DS.sans(.caption, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .dsCard(padding: 14)
    }

    // MARK: - Subject levels (par matière, sans graphe)

    private var subjectLevelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.text("profile.mastery.title").uppercased())
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.inkTertiary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 14
            ) {
                ForEach(Subject.allCases, id: \.self) { subject in
                    SubjectProgressCard(
                        subject: subject,
                        xp: progressManager.xp(for: subject)
                    )
                }
            }
        }
    }
}

// MARK: - Calm progress bar

struct CalmProgressBar: View {
    let fraction: Double
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.hairline)
                Capsule()
                    .fill(DS.accent)
                    .frame(width: max(fraction > 0 ? height : 0, geo.size.width * CGFloat(fraction)))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Profile press feedback

struct ProfileCardPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Subject progress card

private struct SubjectProgressCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let subject: Subject
    let xp: Int

    private static let tiers: [(level: Int, lower: Int, upper: Int)] = ProgressManager.subjectXPTiers

    private var currentTier: (level: Int, lower: Int, upper: Int) {
        Self.tiers.last(where: { xp >= $0.lower }) ?? Self.tiers[0]
    }

    private var progressInLevel: Double {
        let tier = currentTier
        if tier.level == ProgressManager.maxSubjectLevel { return 1.0 }
        let span = max(1, tier.upper - tier.lower)
        let inLevel = max(0, xp - tier.lower)
        return min(1.0, Double(inLevel) / Double(span))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: subject.icon)
                    .font(.jakarta(size: 18, weight: .medium))
                    .foregroundStyle(DS.accentSoft)
                    .frame(width: 44, height: 44)
                    .background(DS.accentTint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Spacer(minLength: 0)
                Text(String(format: languageManager.text("common.levelShort"), currentTier.level))
                    .font(DS.sans(.caption2, .semibold))
                    .foregroundStyle(DS.accentSoft)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(DS.accentTint, in: Capsule())
            }

            Text(subject.localizedShortName(language: languageManager.current))
                .font(DS.title(.subheadline, .semibold))
                .foregroundStyle(DS.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            CalmProgressBar(fraction: progressInLevel, height: 6)

            Text(progressLabel)
                .font(DS.sans(.caption2, .medium))
                .foregroundStyle(DS.inkSecondary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
        .dsCard(padding: 14)
    }

    private var progressLabel: String {
        let tier = currentTier
        if tier.level == ProgressManager.maxSubjectLevel {
            return String(format: languageManager.text("profile.progress.max"), xp)
        }
        let toNext = max(0, tier.upper - xp)
        return String(format: languageManager.text("profile.progress.toNext"), xp, toNext, tier.level + 1)
    }
}

// MARK: - Global rank progress ring

struct GlobalRankRing: View {
    let progress: GlobalLevelProgress
    var size: CGFloat = 96

    @State private var appeared = false

    private var inner: CGFloat { size * 0.7 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(DS.hairline, lineWidth: size * 0.07)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: appeared ? CGFloat(progress.progressToNextRank) : 0)
                .stroke(
                    LinearGradient(
                        colors: [progress.rank.primaryColor, progress.rank.secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)
                .animation(.easeOut(duration: 0.9), value: appeared)

            ZStack {
                Circle()
                    .fill(progress.rank.primaryColor.opacity(0.16))
                    .frame(width: inner, height: inner)
                Image(systemName: progress.rank.symbolName)
                    .font(.jakarta(size: inner * 0.42, weight: .semibold))
                    .foregroundStyle(progress.rank.primaryColor)
            }
            .scaleEffect(appeared ? 1 : 0.8)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Subject mastery radar (hexagon)

private struct SubjectRadarChart: View {
    let values: [(subject: Subject, value: Double)]

    @State private var appeared = false

    private func angle(_ i: Int) -> Double { -.pi / 2 + Double(i) * (.pi / 3) }

    private func point(_ center: CGPoint, _ radius: CGFloat, _ i: Int) -> CGPoint {
        CGPoint(x: center.x + cos(angle(i)) * radius, y: center.y + sin(angle(i)) * radius)
    }

    private func hexPath(_ center: CGPoint, _ radius: CGFloat) -> Path {
        var p = Path()
        for i in 0..<6 {
            let pt = point(center, radius, i)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }

    private func dataPath(_ center: CGPoint, _ maxR: CGFloat, _ scale: CGFloat) -> Path {
        var p = Path()
        for i in 0..<6 {
            let r = max(2, maxR * CGFloat(values[i].value) * scale)
            let pt = point(center, r, i)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let maxR = side / 2 - 30
            let scale: CGFloat = appeared ? 1 : 0.001

            ZStack {
                ForEach(1...3, id: \.self) { ring in
                    hexPath(center, maxR * CGFloat(ring) / 3)
                        .stroke(DS.hairline, lineWidth: 1)
                }

                Path { p in
                    for i in 0..<6 {
                        p.move(to: center)
                        p.addLine(to: point(center, maxR, i))
                    }
                }
                .stroke(DS.hairline, lineWidth: 1)

                dataPath(center, maxR, scale)
                    .fill(DS.accentSoft.opacity(0.16))

                dataPath(center, maxR, scale)
                    .stroke(DS.accentSoft, lineWidth: 2)

                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(DS.accentSoft)
                        .frame(width: 8, height: 8)
                        .position(point(center, max(2, maxR * CGFloat(values[i].value) * scale), i))
                }

                ForEach(0..<6, id: \.self) { i in
                    Image(systemName: values[i].subject.icon)
                        .font(.jakarta(size: 16, weight: .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .position(point(center, maxR + 22, i))
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.15)) {
                    appeared = true
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Quiz row

private struct QuizRowView: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let score: Int
    let total: Int
    let onRetry: () -> Void

    /// Score on /5 scale.
    private var fiveScore: Int {
        guard total > 0 else { return 0 }
        return max(0, min(5, Int(round(Double(score) / Double(total) * 5))))
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(course.title)
                    .font(DS.title(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < fiveScore ? "star.fill" : "star")
                            .font(.jakarta(size: 11, weight: .medium))
                            .foregroundStyle(i < fiveScore ? DS.accentSoft : DS.inkTertiary)
                    }
                    Text("\(fiveScore)/5")
                        .font(DS.sans(.caption2, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .padding(.leading, 4)
                }
            }

            Spacer(minLength: 8)

            Button(action: onRetry) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.jakarta(size: 11, weight: .semibold))
                    Text(languageManager.text("profile.quiz.retry"))
                        .font(DS.sans(.caption, .semibold))
                }
                .foregroundStyle(DS.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DS.accentTint, in: Capsule())
            }
            .buttonStyle(ProfileCardPress())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - All quizzes screen

struct AllQuizzesView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    var onDismiss: () -> Void
    @State private var hapticTrigger: Int = 0

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(languageManager.text("profile.quiz.all"))
                            .font(DS.title(.largeTitle, .semibold))
                            .foregroundStyle(DS.ink)
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.jakarta(size: 15, weight: .medium))
                                .foregroundStyle(DS.inkSecondary)
                                .frame(width: 40, height: 40)
                                .background(DS.surface, in: Circle())
                                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    Color.clear.frame(height: 0)
                    Group {

                    if progressManager.recentQuizzes.isEmpty {
                        Text(languageManager.text("profile.quiz.none"))
                            .font(DS.sans(.subheadline))
                            .foregroundStyle(DS.inkSecondary)
                            .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(progressManager.recentQuizzes.enumerated()), id: \.element.course.id) { idx, item in
                                QuizRowView(
                                    course: item.course,
                                    score: item.score,
                                    total: item.totalPoints,
                                    onRetry: {
                                        hapticTrigger += 1
                                        selectedCourse = item.course
                                    }
                                )
                                if idx < progressManager.recentQuizzes.count - 1 {
                                    Rectangle().fill(DS.hairline).frame(height: 1)
                                }
                            }
                        }
                        .dsCard(padding: 0)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    }
                }
            }
            .scrollIndicators(.hidden)
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
                    .font(.jakarta(size: 15, weight: .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }
            .padding(.trailing, 20)
            .padding(.top, 10)
        }
        .onChange(of: selectedCourse) { _, newValue in
            if newValue != nil { onDismiss() }
        }
    }
}
