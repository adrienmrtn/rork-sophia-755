import SwiftUI

struct ProfileView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let store: StoreViewModel
    @Binding var selectedCourse: Course?
    var onShowPaywall: (() -> Void)? = nil
    var onResetOnboarding: (() -> Void)? = nil

    @State private var showSettings: Bool = false
    @State private var showFavorites: Bool = false
    @State private var showAllQuizzes: Bool = false
    @State private var showAllCards: Bool = false
    @State private var showPendingGlobalRankUp: Bool = false
    @State private var hapticTrigger: Int = 0
    @State private var appeared: Bool = false
    @State private var showSubjectDetails: Bool = false

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    var body: some View {
        NavigationStack {
            ZStack {
                cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        titleBar
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                        identityHeader
                            .padding(.horizontal, 20)

                        bentoStats
                            .padding(.horizontal, 20)

                        radarSection
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
            .fullScreenCover(isPresented: $showAllCards) {
                AllCardsView(
                    progressManager: progressManager,
                    onDismiss: { showAllCards = false }
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
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
            if progressManager.pendingGlobalRankUp() != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if !showSettings && !showFavorites && !showAllQuizzes && !showAllCards {
                        showPendingGlobalRankUp = true
                    }
                }
            }
        }
    }

    // MARK: - Title bar (custom title + gear)

    private var titleBar: some View {
        HStack(alignment: .center) {
            Text(languageManager.text("profile.title"))
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

    // MARK: - Identity header (rank ring + nickname + streak inline)

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
        let streak = progressManager.streak

        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(ink)
                .offset(y: 7)

            HStack(alignment: .center, spacing: 16) {
                GlobalRankRing(progress: p, size: 104)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(String(format: languageManager.text("common.levelShort"), p.level))
                            .font(.system(.caption2, design: .rounded, weight: .black))
                            .foregroundStyle(.white)
                            .tracking(0.6)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(ink, in: Capsule())
                        Text(p.rank.localizedName(language: languageManager.current))
                            .font(.system(.caption, design: .rounded, weight: .black))
                            .foregroundStyle(ink.opacity(0.55))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    Text(nickname)
                        .font(.system(size: 25, weight: .heavy, design: .rounded))
                        .foregroundStyle(ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)

                    streakInlineChip(streak)
                }

                Spacer(minLength: 0)
            }
            .padding(18)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(ink, lineWidth: 3)
            }
        }
        .padding(.bottom, 7)
    }

    private func streakInlineChip(_ streak: Int) -> some View {
        HStack(spacing: 6) {
            AnimatedFlameBadge(size: 15, showGlow: false)
            Text("\(streak)")
                .font(.system(.subheadline, design: .rounded, weight: .black))
                .foregroundStyle(ink)
                .monospacedDigit()
            Text(streak <= 1 ? languageManager.text("common.streak.day") : languageManager.text("common.streak.days"))
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .foregroundStyle(ink.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(BrutalPalette.pastel(for: .histoire), in: Capsule())
        .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
    }

    // MARK: - Bento stats

    private var completedCoursesCount: Int {
        ContentCatalog.activeCourses.filter { progressManager.courseStatus(for: $0.id) == .completed }.count
    }

    private var bentoStats: some View {
        let stats = progressManager.quizStatsSummary
        let cardsUnlocked = progressManager.unlockedCards.count
        let cardsTotal = ContentCatalog.activeCards.count

        return VStack(spacing: 14) {
            streakTile

            HStack(spacing: 14) {
                bentoTile(
                    icon: "checkmark.seal.fill",
                    iconFill: BrutalPalette.pastel(for: .sciences),
                    value: "\(completedCoursesCount)",
                    label: languageManager.text("profile.stats.coursesDone")
                )
                bentoTile(
                    icon: "target",
                    iconFill: BrutalPalette.pink,
                    value: "\(stats.successPercent)%",
                    label: languageManager.text("cards.successRate")
                )
            }

            cardsTile(unlocked: cardsUnlocked, total: cardsTotal)
        }
    }

    private var streakTile: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(ink).offset(y: 5)
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 10) {
                    AnimatedFlameBadge(size: 34, showGlow: false)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(progressManager.streak)")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(ink)
                            .contentTransition(.numericText())
                        Text(progressManager.streak <= 1 ? languageManager.text("common.streak.day") : languageManager.text("common.streak.days"))
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.7))
                    }
                    Spacer()
                }
                weekStrip
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BrutalPalette.pastel(for: .histoire))
            .clipShape(.rect(cornerRadius: 22))
            .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(ink, lineWidth: 3) }
        }
        .padding(.bottom, 5)
    }

    private func bentoTile(icon: String, iconFill: Color, value: String, label: String) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(ink).offset(y: 5)
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(ink)
                    .frame(width: 40, height: 40)
                    .background(iconFill, in: Circle())
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                Text(value)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(ink)
                    .monospacedDigit()
                Text(label)
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .foregroundStyle(ink.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .padding(14)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(ink, lineWidth: 2.5) }
        }
        .padding(.bottom, 5)
    }

    private func cardsTile(unlocked: Int, total: Int) -> some View {
        let fraction = total == 0 ? 0 : Double(unlocked) / Double(total)
        return Button {
            hapticTrigger += 1
            showAllCards = true
        } label: {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(ink).offset(y: 5)
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(ink)
                            .frame(width: 40, height: 40)
                            .background(BrutalPalette.yellow, in: Circle())
                            .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(unlocked)")
                                .font(.system(size: 30, weight: .black, design: .rounded))
                                .foregroundStyle(ink)
                                .monospacedDigit()
                            Text("/ \(total)")
                                .font(.system(.subheadline, design: .rounded, weight: .black))
                                .foregroundStyle(ink.opacity(0.45))
                        }

                        Spacer()

                        Text(languageManager.text("profile.stats.cards"))
                            .font(.system(.caption, design: .rounded, weight: .black))
                            .foregroundStyle(ink.opacity(0.55))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(ink)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white).overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                            Capsule()
                                .fill(LinearGradient(colors: [BrutalPalette.pink, BrutalPalette.yellow], startPoint: .leading, endPoint: .trailing))
                                .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                                .frame(width: max(14, geo.size.width * CGFloat(fraction)))
                        }
                    }
                    .frame(height: 14)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(.rect(cornerRadius: 20))
                .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(ink, lineWidth: 2.5) }
            }
            .padding(.bottom, 5)
        }
        .buttonStyle(BrutalCardButtonStyle(depth: 3))
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
                    Text(languageManager.text("profile.favorites"))
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                    Text(String(format: languageManager.text("profile.favorites.count"), progressManager.favoriteCourses.count))
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
                Text(languageManager.text("profile.quiz.recent"))
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.55))
                    .tracking(1.2)
                Spacer()
                if store.isPremium && !progressManager.recentQuizzes.isEmpty {
                    Button {
                        hapticTrigger += 1
                        showAllQuizzes = true
                    } label: {
                        Text(languageManager.text("common.seeMoreArrow"))
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink)
                    }
                }
            }
            .padding(.horizontal, 8)

            if progressManager.recentQuizzes.isEmpty {
                emptyQuizzesCard
            } else if store.isPremium {
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
            } else {
                emptyQuizzesCard
            }
        }
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
                Text(languageManager.text("profile.quiz.emptyTitle"))
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                Text(languageManager.text("profile.quiz.emptySubtitle"))
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .brutalCard()
    }

    // MARK: - Subject mastery radar

    private var radarValues: [(subject: Subject, value: Double)] {
        Subject.allCases.map { subject in
            (subject, max(0.06, min(1.0, Double(progressManager.xp(for: subject)) / 700.0)))
        }
    }

    private var radarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(languageManager.text("profile.mastery.title"))
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.55))
                    .tracking(1.2)
                Spacer()
            }
            .padding(.horizontal, 8)

            Button {
                hapticTrigger += 1
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    showSubjectDetails.toggle()
                }
            } label: {
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous).fill(ink).offset(y: 5)
                    VStack(spacing: 10) {
                        SubjectRadarChart(values: radarValues)
                            .frame(height: 250)

                        HStack(spacing: 6) {
                            Text(languageManager.text(showSubjectDetails ? "profile.mastery.hide" : "profile.mastery.details"))
                                .font(.system(.caption, design: .rounded, weight: .black))
                                .foregroundStyle(ink.opacity(0.6))
                            Image(systemName: showSubjectDetails ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(ink.opacity(0.6))
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .clipShape(.rect(cornerRadius: 22))
                    .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(ink, lineWidth: 3) }
                }
                .padding(.bottom, 5)
            }
            .buttonStyle(BrutalCardButtonStyle(depth: 3))

            if showSubjectDetails {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(Subject.allCases, id: \.self) { subject in
                        SubjectProgressCard(
                            subject: subject,
                            xp: progressManager.xp(for: subject)
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Subject progress card

private struct SubjectProgressCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let subject: Subject
    let xp: Int

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

            VStack(alignment: .leading, spacing: 10) {
                SubjectBadgeView(subject: subject, unlocked: true, emojiSize: 36, cornerRadius: 14)
                    .frame(width: 56, height: 56)

                Text(subject.localizedShortName(language: languageManager.current))
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(String(format: languageManager.text("common.levelShort"), currentTier.level))
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(0.6)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ink, in: Capsule())

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(white: 0.94))
                            .overlay { Capsule().strokeBorder(ink, lineWidth: 1.5) }
                        Capsule()
                            .fill(BrutalPalette.pastel(for: subject))
                            .overlay { Capsule().strokeBorder(ink, lineWidth: 1.5) }
                            .frame(width: max(8, geo.size.width * progressInLevel))
                    }
                }
                .frame(height: 8)

                Text(progressLabel)
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.55))
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(ink, lineWidth: 2.5)
            }
        }
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, minHeight: 176, maxHeight: 176)
    }

    private var progressLabel: String {
        let tier = currentTier
        if tier.level == 5 {
            return String(format: languageManager.text("profile.progress.max"), xp)
        }
        let toNext = max(0, tier.upper - xp)
        return String(format: languageManager.text("profile.progress.toNext"), xp, toNext, tier.level + 1)
    }
}

// MARK: - Global rank progress ring

private struct GlobalRankRing: View {
    let progress: GlobalLevelProgress
    var size: CGFloat = 104

    @State private var appeared = false
    private let ink = BrutalPalette.ink

    var body: some View {
        ZStack {
            Circle()
                .stroke(ink.opacity(0.1), lineWidth: size * 0.085)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: appeared ? CGFloat(progress.progressToNextRank) : 0)
                .stroke(
                    LinearGradient(
                        colors: [progress.rank.primaryColor, progress.rank.secondaryColor, progress.rank.primaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: size * 0.085, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)

            GlobalRankAnimatedIcon(rank: progress.rank, size: size * 0.7, intensity: .profile)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.82).delay(0.15)) {
                appeared = true
            }
        }
    }
}

// MARK: - Subject mastery radar (hexagon)

private struct SubjectRadarChart: View {
    let values: [(subject: Subject, value: Double)]

    @State private var appeared = false
    private let ink = BrutalPalette.ink

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
                        .stroke(ink.opacity(0.12), lineWidth: 1.5)
                }

                Path { p in
                    for i in 0..<6 {
                        p.move(to: center)
                        p.addLine(to: point(center, maxR, i))
                    }
                }
                .stroke(ink.opacity(0.12), lineWidth: 1.5)

                dataPath(center, maxR, scale)
                    .fill(
                        LinearGradient(
                            colors: [BrutalPalette.pink.opacity(0.4), BrutalPalette.yellow.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                dataPath(center, maxR, scale)
                    .stroke(ink, lineWidth: 2.5)

                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(BrutalPalette.pink)
                        .frame(width: 9, height: 9)
                        .overlay { Circle().strokeBorder(ink, lineWidth: 1.8) }
                        .position(point(center, max(2, maxR * CGFloat(values[i].value) * scale), i))
                }

                ForEach(0..<6, id: \.self) { i in
                    Text(values[i].subject.emoji)
                        .font(.system(size: 22))
                        .position(point(center, maxR + 20, i))
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
                    Text(languageManager.text("profile.quiz.retry"))
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
    @Environment(LanguageManager.self) private var languageManager
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
                        Text(languageManager.text("profile.quiz.all"))
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
                        Text(languageManager.text("profile.quiz.none"))
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
