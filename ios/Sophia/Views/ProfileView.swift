import SwiftUI

/// La page « Ma progression » : une illustration papier (style du site), le niveau et sa barre
/// d'XP, la série, les compteurs, la progression par matière, le rang global, les quiz récents,
/// le classement entre amis et les raccourcis (anti-scroll, favoris, partage).
/// Poussée depuis le profil (`embedded`), ou racine de l'onglet Profil de la navigation classique.
struct ProfileView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth
    let progressManager: ProgressManager
    let store: StoreViewModel
    @Binding var selectedCourse: Course?
    var onShowPaywall: (() -> Void)? = nil
    /// The anti-scroll paywall (`.blocker`), for the TikTok blocker card and its settings.
    var onShowBlockerPaywall: (() -> Void)? = nil
    var onResetOnboarding: (() -> Void)? = nil
    /// Vrai quand la page est poussée dans la pile d'un autre écran (pas de pile à elle).
    var embedded: Bool = false

    @State private var showSettings: Bool = false
    @State private var showFavorites: Bool = false
    @State private var showAllQuizzes: Bool = false
    @State private var showPendingGlobalRankUp: Bool = false
    @State private var showEditHandle: Bool = false
    @State private var showTikTokBlocker: Bool = false
    @State private var showAntiScrollIntro: Bool = false
    @State private var showShare: Bool = false
    @Bindable private var social = SocialService.shared

    /// Safran des illustrations du site (flamme, jour en cours, rang en cours).
    fileprivate static let saffron = Color(red: 0.902, green: 0.698, blue: 0.200)

    var body: some View {
        Group {
            if embedded {
                page
            } else {
                NavigationStack { page }
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
            if progressManager.pendingGlobalRankUp() != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if !showSettings && !showFavorites && !showAllQuizzes {
                        showPendingGlobalRankUp = true
                    }
                }
            }
        }
    }

    /// Le contenu de la page. Racine d'onglet (navigation classique), il vit dans sa propre pile
    /// de navigation ; poussé depuis le nouveau profil (« Ma progression »), il s'insère dans la
    /// pile qui l'a poussé (SwiftUI ne prend pas en charge une pile imbriquée dans une destination).
    private var page: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                        .dsStagger(0, offset: 0)
                    sections
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)
        }
        // Page poussée : la barre du système reste, c'est elle qui porte le bouton retour.
        .navigationBarHidden(!embedded)
        .fullScreenCover(isPresented: $showTikTokBlocker) {
            TikTokBlockerSettingsView(
                store: store,
                onShowPaywall: {
                    // The settings cover has to be gone before the paywall cover comes
                    // up, or the two presentations race and neither appears.
                    showTikTokBlocker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        (onShowBlockerPaywall ?? onShowPaywall)?()
                    }
                },
                presentedAsCover: true
            )
            .sophiaColorScheme()
        }
        .sheet(isPresented: $showShare) {
            ShareSophiaSheet()
                .sophiaSheetChrome()
        }
        // « Active l'anti-scroll » : l'explication d'abord, puis les réglages (membre) ou
        // le paywall du blocker.
        .sheet(isPresented: $showAntiScrollIntro) {
            AntiScrollIntroSheet {
                showAntiScrollIntro = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if store.isPremium {
                        showTikTokBlocker = true
                    } else {
                        (onShowBlockerPaywall ?? onShowPaywall)?()
                    }
                }
            }
            .sophiaSheetChrome()
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(
                progressManager: progressManager,
                store: store,
                onShowPaywall: onShowPaywall,
                onResetOnboarding: onResetOnboarding,
                onDismiss: { showSettings = false }
            )
            .sophiaColorScheme()
        }
        .fullScreenCover(isPresented: $showFavorites) {
            FavoritesSheet(
                progressManager: progressManager,
                selectedCourse: $selectedCourse,
                onDismiss: { showFavorites = false }
            )
            .sophiaColorScheme()
        }
        .fullScreenCover(isPresented: $showAllQuizzes) {
            AllQuizzesView(
                progressManager: progressManager,
                selectedCourse: $selectedCourse,
                onDismiss: { showAllQuizzes = false }
            )
            .sophiaColorScheme()
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
                .sophiaColorScheme()
            }
        }
        .sheet(isPresented: $showEditHandle) {
            if let handle = social.myHandle {
                EditHandleSheet(currentHandle: handle) { _ in
                    Task { await social.refreshAll() }
                }
                .presentationDetents([.medium])
                .sophiaSheetChrome()
            }
        }
    }

    /// Les blocs de la page, chacun révélé à son tour (cascade courte, jamais bloquante).
    private var sections: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBar
                .dsStagger(1)
            levelCard
                .padding(.top, 14)
                .dsStagger(2)
            streakCard
                .padding(.top, 10)
                .dsStagger(3)
            statsGrid
                .padding(.top, 10)
                .dsStagger(4)
            subjectsSection
                .padding(.top, 24)
                .dsStagger(5)
            rankSection
                .padding(.top, 24)
                .dsStagger(6)
            quizSection
                .padding(.top, 24)
                .dsStagger(7)
            FriendsLeaderboardSection(social: social)
                .padding(.top, 24)
                .dsStagger(8)
            shortcutsCard
                .padding(.top, 18)
                .dsStagger(9)
        }
    }

    // MARK: - Illustration

    /// L'illustration papier du site (`progress_hero`), en bandeau bord à bord en tête de page.
    private var hero: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .overlay {
                Image("progress_hero")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .clipped()
            .accessibilityHidden(true)
    }

    // MARK: - Titre

    private var titleBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(languageManager.text(embedded ? "progress.title" : "profile.title"))
                .font(DS.title(.title, .semibold))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            ProfileRoundButton(
                systemImage: "gearshape",
                accessibilityLabel: languageManager.text("settings.title")
            ) {
                showSettings = true
            }
        }
    }

    // MARK: - Niveau

    private var nickname: String {
        ProfileIdentity.rankTitle(languageManager: languageManager)
    }

    /// Part du niveau en cours déjà parcourue (0…1) ; 1 au niveau maximal.
    private func levelFraction(_ p: GlobalLevelProgress) -> Double {
        guard p.level < 100 else { return 1 }
        let lower = ProgressManager.xpThreshold(forGlobalLevel: p.level)
        let upper = ProgressManager.xpThreshold(forGlobalLevel: p.level + 1)
        let span = max(1, upper - lower)
        return min(1, max(0, Double(p.xp - lower) / Double(span)))
    }

    /// « 1240 XP · 60 avant niv. 13 », ou « 1240 XP · niveau max ».
    private func levelCaption(_ p: GlobalLevelProgress) -> String {
        guard p.level < 100 else {
            return String(format: languageManager.text("profile.progress.max"), p.xp)
        }
        let upper = ProgressManager.xpThreshold(forGlobalLevel: p.level + 1)
        let toNext = max(0, upper - p.xp)
        return String(format: languageManager.text("profile.progress.toNext"), p.xp, toNext, p.level + 1)
    }

    private var levelCard: some View {
        let p: GlobalLevelProgress = progressManager.globalLevelProgress

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 14) {
                levelDisc(p.level)
                levelTexts(p)
                Spacer(minLength: 0)
            }

            ProfileFillBar(fraction: levelFraction(p), height: 8, delay: 0.3)

            Text(levelCaption(p))
                .font(DS.sans(.footnote))
                .foregroundStyle(DS.inkSecondary)
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
        }
        .dsCard(padding: 16)
    }

    private func levelDisc(_ level: Int) -> some View {
        Text("\(level)")
            .font(DS.title(.title, .heavy))
            .foregroundStyle(.white)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 6)
            .frame(width: 64, height: 64)
            .background(Circle().fill(DS.accent))
            .dsPopIn(delay: 0.2)
            .accessibilityHidden(true)
    }

    private func levelTexts(_ p: GlobalLevelProgress) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(format: languageManager.text("path.levelCaption"), p.level))
                .font(DS.title(.headline, .heavy))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(nickname)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if auth.isSignedIn, let handle = social.myHandle {
                Button {
                    showEditHandle = true
                } label: {
                    HStack(spacing: 6) {
                        Text("@\(handle)")
                            .font(DS.sans(.footnote, .bold))
                            .lineLimit(1)
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(DS.accent)
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
            }
        }
    }

    // MARK: - Série

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                // Flamme fixe : plus d'animation sur cette page.
                Image(systemName: "flame.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Self.saffron)
                    .accessibilityHidden(true)

                Text(languageManager.text("friends.stats.streak"))
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.ink)

                Spacer(minLength: 8)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    ProfileCountText(
                        value: progressManager.streak,
                        font: DS.sans(.subheadline, .heavy)
                    )
                    Text(progressManager.streak <= 1 ? languageManager.text("common.streak.day") : languageManager.text("common.streak.days"))
                        .font(DS.sans(.subheadline, .heavy))
                        .foregroundStyle(DS.ink)
                }
            }
            .accessibilityElement(children: .combine)

            weekStrip
        }
        .dsCard(padding: 16)
    }

    /// Les sept jours de la rangée de série, dans l'ordre d'affichage.
    private var weekDays: [ProgressDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayLetters = languageManager.current.mondayFirstWeekdayLetters

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let lastActive = progressManager.progress.lastActiveDate
        let streak = progressManager.streak
        // La première case est le premier jour de la série, pas le lundi.
        let firstDay = StreakWeek.firstDay(streak: streak, lastActive: lastActive, today: today, calendar: calendar)

        var days: [ProgressDay] = []
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: firstDay) ?? today
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let isFuture = date > today
            let dateStr = fmt.string(from: date)

            var isDone = false
            if !isFuture, let last = lastActive, let lastDate = fmt.date(from: last) {
                let daysFromLast = calendar.dateComponents([.day], from: date, to: lastDate).day ?? 999
                isDone = dateStr <= last && daysFromLast >= 0 && daysFromLast < streak
            }

            days.append(
                ProgressDay(
                    id: i,
                    letter: dayLetters[StreakWeek.letterIndex(of: date, calendar: calendar)],
                    isDone: isDone,
                    isToday: isToday,
                    isFuture: isFuture
                )
            )
        }
        return days
    }

    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(weekDays) { day in
                dayCell(day)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private func dayCell(_ day: ProgressDay) -> some View {
        VStack(spacing: 5) {
            ZStack {
                if day.isDone {
                    Circle().fill(DS.accent)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                    if day.isToday {
                        Circle().strokeBorder(Self.saffron, lineWidth: 2.5)
                    }
                } else if day.isToday {
                    Circle().fill(DS.surface)
                    Circle().strokeBorder(Self.saffron, lineWidth: 2.5)
                } else {
                    Circle().fill(DS.surface)
                    Circle().strokeBorder(DS.hairline, lineWidth: 1.5)
                }
            }
            .frame(width: 30, height: 30)
            .opacity(day.isFuture ? 0.55 : 1)
            .dsPopIn(delay: 0.25 + Double(day.id) * 0.04)

            Text(day.letter)
                .font(DS.sans(.caption2, .bold))
                .foregroundStyle(day.isToday ? DS.ink : DS.inkSecondary)
        }
    }

    // MARK: - Compteurs

    private var completedCoursesCount: Int {
        ContentCatalog.activeCourses.filter { progressManager.courseStatus(for: $0.id) == .completed }.count
    }

    private var statsGrid: some View {
        let stats = progressManager.quizStatsSummary
        let columns: [GridItem] = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

        return LazyVGrid(columns: columns, spacing: 10) {
            statTile(
                value: completedCoursesCount,
                label: languageManager.text("profile.stats.coursesDone")
            )
            statTile(
                value: stats.completedQuizCount,
                label: languageManager.text("progress.stats.quizzes")
            )
            statTile(
                value: stats.successPercent,
                suffix: "%",
                label: languageManager.text("progress.stats.successRate")
            )
            statTile(
                value: progressManager.globalLevelProgress.xp,
                label: languageManager.text("progress.stats.xp"),
                haptics: true
            )
        }
    }

    private func statTile(value: Int, suffix: String = "", label: String, haptics: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ProfileCountText(
                value: value,
                suffix: suffix,
                font: DS.title(.title2, .heavy),
                haptics: haptics
            )
            Text(label)
                .font(DS.sans(.footnote))
                .foregroundStyle(DS.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)
        .dsCard(padding: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(value)\(suffix), \(label)"))
    }

    // MARK: - Par matière

    private var subjectsSection: some View {
        let subjects: [Subject] = Subject.allCases

        return VStack(alignment: .leading, spacing: 8) {
            ProfileSectionHeader(title: languageManager.text("progress.subjects.title"))

            ForEach(Array(subjects.enumerated()), id: \.element) { index, subject in
                SubjectProgressRow(subject: subject, xp: progressManager.xp(for: subject), index: index)
            }
        }
    }

    // MARK: - Rang global

    private func rankCaption(_ p: GlobalLevelProgress) -> String {
        if let toNext = p.xpToNextRank, let next = p.rank.next {
            return String(
                format: languageManager.text("globalRank.xpBefore"),
                toNext,
                next.localizedName(language: languageManager.current)
            )
        }
        return languageManager.text("globalRank.maxLevel")
    }

    private var rankSection: some View {
        let p: GlobalLevelProgress = progressManager.globalLevelProgress

        return VStack(alignment: .leading, spacing: 10) {
            ProfileSectionHeader(title: languageManager.text("globalRank.title"))

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    GlobalRankRing(progress: p, size: 56)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.rank.localizedName(language: languageManager.current))
                            .font(DS.title(.headline, .heavy))
                            .foregroundStyle(DS.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(rankCaption(p))
                            .font(DS.sans(.footnote))
                            .foregroundStyle(DS.inkSecondary)
                            .monospacedDigit()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)

                rankLadder(current: p.rank)
            }
            .dsCard(padding: 16)
        }
    }

    /// Les cinq rangs, du premier au dernier : ceux déjà atteints en plein, le rang en cours cerclé de safran.
    private func rankLadder(current: GlobalRank) -> some View {
        let ranks: [GlobalRank] = GlobalRank.allCases
        let currentIndex: Int = ranks.firstIndex(of: current) ?? 0

        return HStack(alignment: .top, spacing: 4) {
            ForEach(Array(ranks.enumerated()), id: \.element) { index, rank in
                rankStep(rank: rank, reached: index <= currentIndex, isCurrent: index == currentIndex, index: index)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private func rankStep(rank: GlobalRank, reached: Bool, isCurrent: Bool, index: Int) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().fill(reached ? DS.accent : DS.surface)
                if isCurrent {
                    Circle().strokeBorder(Self.saffron, lineWidth: 3)
                } else if !reached {
                    Circle().strokeBorder(DS.hairline, lineWidth: 1.5)
                }
                Image(systemName: rank.symbolName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(reached ? Color.white : DS.inkTertiary)
            }
            .frame(width: 30, height: 30)
            .dsPopIn(delay: 0.2 + Double(index) * 0.05)

            Text(rank.localizedName(language: languageManager.current))
                .font(DS.sans(.caption2, .bold))
                .foregroundStyle(reached ? DS.ink : DS.inkSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Quiz récents

    private var quizSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProfileSectionHeader(title: languageManager.text("progress.quizzes.title")) {
                if store.isPremium && !progressManager.recentQuizzes.isEmpty {
                    ProfileHeaderLink(title: languageManager.text("common.seeMoreArrow"), showsChevron: false) {
                        showAllQuizzes = true
                    }
                }
            }

            if progressManager.recentQuizzes.isEmpty {
                emptyQuizzesCard
            } else if store.isPremium {
                VStack(spacing: 8) {
                    ForEach(Array(progressManager.recentQuizzes.prefix(3).enumerated()), id: \.element.course.id) { _, item in
                        QuizRowView(
                            course: item.course,
                            score: item.score,
                            total: item.totalPoints,
                            onRetry: {
                                AnalyticsService.shared.pendingCourseOpenSource = .profile; selectedCourse = item.course
                            }
                        )
                    }
                }
            } else {
                emptyQuizzesCard
            }
        }
    }

    private var emptyQuizzesCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(languageManager.text("profile.quiz.emptyTitle"))
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(languageManager.text("profile.quiz.emptySubtitle"))
                    .font(DS.sans(.footnote))
                    .foregroundStyle(DS.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .dsCard(padding: 16)
    }

    // MARK: - Raccourcis (anti-scroll, favoris, partage)

    /// "Cultive-toi avant de scroller", where the daily goal lives. One row, four
    /// states: not Premium, off, locked (finish today's course), done (well played).
    private struct BlockerCardState {
        let icon: String
        let tint: Color
        let title: String
        let subtitle: String
    }

    /// One of four states, resolved in plain statements: the tuple-returning closure this
    /// replaced was a type-checker sink.
    private var blockerCardState: BlockerCardState {
        let blocker = TikTokBlockerManager.shared
        if !store.isPremium {
            return BlockerCardState(
                icon: "lock", tint: DS.accent,
                title: languageManager.text("tiktokBlocker.card.premium.title"),
                subtitle: languageManager.text("tiktokBlocker.card.premium.subtitle")
            )
        }
        if !blocker.isArmed {
            return BlockerCardState(
                icon: "lock", tint: DS.accent,
                title: languageManager.text("tiktokBlocker.card.off.title"),
                subtitle: languageManager.text("tiktokBlocker.card.off.subtitle")
            )
        }
        if blocker.isUnlockWindowOpen {
            return BlockerCardState(
                icon: "checkmark.seal.fill", tint: DS.success,
                title: languageManager.text("tiktokBlocker.card.done.title"),
                subtitle: languageManager.text("tiktokBlocker.card.done.subtitle")
            )
        }
        return BlockerCardState(
            icon: "lock.fill", tint: DS.warm,
            title: languageManager.text("tiktokBlocker.card.locked.title"),
            subtitle: languageManager.text("tiktokBlocker.card.locked.subtitle")
        )
    }

    private var shortcutsCard: some View {
        let blockerState: BlockerCardState = blockerCardState

        return VStack(spacing: 0) {
            // Anti-scroll : déjà activé, droit aux réglages ; sinon l'explication d'abord.
            shortcutRow(
                icon: blockerState.icon,
                tint: blockerState.tint,
                title: blockerState.title,
                subtitle: blockerState.subtitle,
                trailingIcon: "chevron.forward"
            ) {
                if TikTokBlockerManager.shared.isEnabled {
                    showTikTokBlocker = true
                } else {
                    showAntiScrollIntro = true
                }
            }

            ProfileRowDivider()
                .padding(.horizontal, 16)

            shortcutRow(
                icon: "bookmark",
                tint: DS.accent,
                title: languageManager.text("profile.favorites"),
                subtitle: String(format: languageManager.text("profile.favorites.count"), progressManager.favoriteCourses.count),
                trailingIcon: "chevron.forward"
            ) {
                showFavorites = true
            }

            ProfileRowDivider()
                .padding(.horizontal, 16)

            // « Partage Sophia · Offre 10 minutes de culture à un ami » : ouvre la feuille de partage.
            shortcutRow(
                icon: "square.and.arrow.up",
                tint: DS.accent,
                title: languageManager.text("share.card.title"),
                subtitle: languageManager.text("share.card.subtitle"),
                trailingIcon: "chevron.forward"
            ) {
                showShare = true
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .dsCard(padding: 0)
    }

    private func shortcutRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        trailingIcon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(DS.sans(.footnote))
                        .foregroundStyle(DS.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: trailingIcon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.inkSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(ProfileRowPressStyle())
    }
}

/// Un jour de la rangée de série : sa lettre et son état.
private struct ProgressDay: Identifiable {
    let id: Int
    let letter: String
    let isDone: Bool
    let isToday: Bool
    let isFuture: Bool
}

// MARK: - Ligne d'une matière

/// Une matière : son illustration ronde, son nom, son niveau, une barre fine qui se remplit et
/// l'XP restant avant le niveau suivant.
private struct SubjectProgressRow: View {
    @Environment(LanguageManager.self) private var languageManager
    let subject: Subject
    let xp: Int
    /// Rang dans la liste, pour la cascade des barres.
    var index: Int = 0

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

    private var progressLabel: String {
        let tier = currentTier
        if tier.level == ProgressManager.maxSubjectLevel {
            return String(format: languageManager.text("profile.progress.max"), xp)
        }
        let toNext = max(0, tier.upper - xp)
        return String(format: languageManager.text("profile.progress.toNext"), xp, toNext, tier.level + 1)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            subjectIcon

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .center, spacing: 8) {
                    Text(subject.localizedShortName(language: languageManager.current))
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    Text(String(format: languageManager.text("common.levelShort"), currentTier.level))
                        .font(DS.sans(.caption2, .heavy))
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(DS.accentTint))
                }

                ProfileFillBar(fraction: progressInLevel, height: 6, delay: 0.3 + Double(index) * 0.06)

                Text(progressLabel)
                    .font(DS.sans(.caption))
                    .foregroundStyle(DS.inkSecondary)
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .dsCard(padding: 12)
        .accessibilityElement(children: .combine)
    }

    /// L'illustration ronde de la matière (celle de son badge) ; à défaut, son pictogramme à sa couleur.
    @ViewBuilder
    private var subjectIcon: some View {
        if let image = UIImage(named: "badge_subject_\(subject.storageKey)") {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .accessibilityHidden(true)
        } else {
            Image(systemName: subject.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(subject.color)
                .frame(width: 36, height: 36)
                .background(Circle().fill(subject.color.opacity(0.16)))
                .accessibilityHidden(true)
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(DS.Motion.press, value: configuration.isPressed)
    }
}

// MARK: - Global rank progress ring

/// L'anneau du rang global : la part du rang déjà parcourue, en bleu, autour du symbole du rang.
struct GlobalRankRing: View {
    let progress: GlobalLevelProgress
    var size: CGFloat = 96

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var inner: CGFloat { size * 0.68 }
    private var lineWidth: CGFloat { max(4, size * 0.09) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(DS.accentTint, lineWidth: lineWidth)
                .padding(lineWidth / 2)

            Circle()
                .trim(from: 0, to: appeared ? CGFloat(progress.progressToNextRank) : 0)
                .stroke(DS.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(lineWidth / 2)

            Image(systemName: progress.rank.symbolName)
                .font(.jakarta(size: inner * 0.42, weight: .semibold))
                .foregroundStyle(DS.accent)
                .scaleEffect(appeared || reduceMotion ? 1 : 0.6)
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !appeared else { return }
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(DS.Motion.reveal.delay(0.2)) {
                    appeared = true
                }
            }
        }
    }
}

// MARK: - Quiz row

/// Un quiz passé, sur sa carte : le titre du cours, la note sur cinq étoiles et « Refaire ».
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
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(i < fiveScore ? DS.warm : DS.hairline)
                    }
                    Text("\(fiveScore)/5")
                        .font(DS.sans(.caption, .bold))
                        .foregroundStyle(DS.ink)
                        .monospacedDigit()
                        .padding(.leading, 4)
                }
            }

            Spacer(minLength: 8)

            Button(action: onRetry) {
                Text(languageManager.text("profile.quiz.retry"))
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(DS.accent)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Capsule().fill(DS.surface))
                    .overlay(Capsule().strokeBorder(DS.accent, lineWidth: 1.5))
                    .contentShape(Capsule())
            }
            .buttonStyle(.pressable)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .dsCard(padding: 0)
    }
}

// MARK: - All quizzes screen

struct AllQuizzesView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(languageManager.text("profile.quiz.all"))
                            .font(DS.title(.title, .semibold))
                            .foregroundStyle(DS.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        ProfileRoundButton(
                            systemImage: "xmark",
                            accessibilityLabel: languageManager.text("common.close"),
                            action: onDismiss
                        )
                    }
                    .padding(.top, 4)

                    if progressManager.recentQuizzes.isEmpty {
                        Text(languageManager.text("profile.quiz.none"))
                            .font(DS.sans(.subheadline))
                            .foregroundStyle(DS.inkSecondary)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(Array(progressManager.recentQuizzes.enumerated()), id: \.element.course.id) { idx, item in
                                QuizRowView(
                                    course: item.course,
                                    score: item.score,
                                    total: item.totalPoints,
                                    onRetry: {
                                        AnalyticsService.shared.pendingCourseOpenSource = .profile; selectedCourse = item.course
                                    }
                                )
                                .dsStagger(min(idx, 8), step: 0.04)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
        .sophiaColorScheme()
    }
}

// MARK: - Favorites sheet wrapper

private struct FavoritesSheet: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    var onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            FavoritesView(
                progressManager: progressManager,
                selectedCourse: $selectedCourse
            )
            ProfileRoundButton(
                systemImage: "xmark",
                accessibilityLabel: languageManager.text("common.close"),
                action: onDismiss
            )
            .padding(.trailing, 20)
            .padding(.top, 10)
        }
        .onChange(of: selectedCourse) { _, newValue in
            if newValue != nil { onDismiss() }
        }
        .sophiaColorScheme()
    }
}
