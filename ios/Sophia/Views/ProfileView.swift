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
    @State private var hapticTrigger: Int = 0
    @State private var appeared: Bool = false
    @Bindable private var social = SocialService.shared

    /// Safran des illustrations du site (flamme, étoiles, XP).
    fileprivate static let saffron = Color(red: 0.949, green: 0.694, blue: 0.204)

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

    /// Le contenu de la page. Racine d'onglet (navigation classique), il vit dans sa propre pile
    /// de navigation ; poussé depuis le nouveau profil (« Ma progression »), il s'insère dans la
    /// pile qui l'a poussé (SwiftUI ne prend pas en charge une pile imbriquée dans une destination).
    private var page: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    titleBar
                    levelCard
                    streakCard
                    statsGrid
                    subjectsSection
                    rankSection
                    quizSection
                    FriendsLeaderboardSection(social: social)
                    shortcutsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
            }
            .scrollIndicators(.hidden)
        }
        // Page poussée : la barre du système reste, c'est elle qui porte le bouton retour.
        .navigationBarHidden(!embedded)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
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

    // MARK: - Illustration

    /// L'illustration papier du site (`progress_hero`, 3:2), en carte arrondie ; sa hauteur est
    /// bornée pour les grands écrans.
    private var hero: some View {
        Image("progress_hero")
            .resizable()
            .aspectRatio(3.0 / 2.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .dsSoftShadow()
            .frame(maxHeight: 300)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }

    // MARK: - Titre

    private var titleBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(languageManager.text(embedded ? "progress.title" : "profile.title"))
                .font(DS.title(.largeTitle, .heavy))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button {
                hapticTrigger += 1
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.ink)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DS.surface))
                    .overlay(Circle().strokeBorder(DS.hairline, lineWidth: 1))
            }
            .buttonStyle(ProfileCardPress())
            .accessibilityLabel(Text(languageManager.text("settings.title")))
        }
    }

    // MARK: - Niveau

    private var nickname: String {
        let interests = OnboardingViewModel.userInterestKeys()
        let keys = Subject.allCases.map(\.storageKey).filter { interests.contains($0) }
        guard let first = keys.first else {
            return languageManager.text("onboarding.program.nickname.default")
        }
        return languageManager.text("onboarding.program.nickname.\(first)")
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
        let p = progressManager.globalLevelProgress

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                Text("\(p.level)")
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 6)
                    .frame(width: 68, height: 68)
                    .background(Circle().fill(DS.accent))
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DS.accent)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Self.saffron))
                            .overlay(Circle().strokeBorder(DS.surface, lineWidth: 2))
                            .offset(x: 4, y: -4)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: languageManager.text("path.levelCaption"), p.level))
                        .font(DS.title(.title2, .heavy))
                        .foregroundStyle(DS.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(nickname)
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.inkSecondary)
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
                                    .lineLimit(1)
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(DS.inkTertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                ProgressPageBar(fraction: levelFraction(p), tint: DS.accent, height: 10)
                Text(levelCaption(p))
                    .font(DS.sans(.footnote, .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .dsCard()
    }

    // MARK: - Série

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                // Flamme fixe : plus d'animation sur cette page.
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Self.saffron)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Self.saffron.opacity(0.16)))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 0) {
                    Text(languageManager.text("friends.stats.streak"))
                        .font(DS.sans(.caption, .semibold))
                        .foregroundStyle(DS.inkSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(progressManager.streak)")
                            .font(DS.title(.title, .heavy))
                            .foregroundStyle(DS.ink)
                            .contentTransition(.numericText())
                            .monospacedDigit()
                        Text(progressManager.streak <= 1 ? languageManager.text("common.streak.day") : languageManager.text("common.streak.days"))
                            .font(DS.sans(.caption, .bold))
                            .foregroundStyle(DS.inkSecondary)
                            .tracking(0.8)
                    }
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)

            weekStrip
        }
        .dsCard()
    }

    private var weekStrip: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayLetters = languageManager.current.mondayFirstWeekdayLetters

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let lastActive = progressManager.progress.lastActiveDate
        let streak = progressManager.streak
        // La première case est le premier jour de la série, pas le lundi.
        let firstDay = StreakWeek.firstDay(streak: streak, lastActive: lastActive, today: today, calendar: calendar)

        return HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { i in
                let date = calendar.date(byAdding: .day, value: i, to: firstDay) ?? today
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
                    Text(dayLetters[StreakWeek.letterIndex(of: date, calendar: calendar)])
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(isToday ? DS.ink : DS.inkTertiary)
                    ZStack {
                        if isDone {
                            Circle().fill(DS.accent)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        } else if isToday {
                            Circle().fill(DS.surface)
                            Circle().strokeBorder(Self.saffron, lineWidth: 2)
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
        .accessibilityHidden(true)
    }

    // MARK: - Compteurs

    private var completedCoursesCount: Int {
        ContentCatalog.activeCourses.filter { progressManager.courseStatus(for: $0.id) == .completed }.count
    }

    private var statsGrid: some View {
        let stats = progressManager.quizStatsSummary
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

        return LazyVGrid(columns: columns, spacing: 12) {
            statTile(
                icon: "book.closed.fill",
                value: "\(completedCoursesCount)",
                label: languageManager.text("profile.stats.coursesDone")
            )
            statTile(
                icon: "checkmark.seal.fill",
                value: "\(stats.completedQuizCount)",
                label: languageManager.text("progress.stats.quizzes")
            )
            statTile(
                icon: "target",
                value: "\(stats.successPercent)%",
                label: languageManager.text("progress.stats.successRate")
            )
            statTile(
                icon: "bolt.fill",
                value: "\(progressManager.globalLevelProgress.xp)",
                label: languageManager.text("progress.stats.xp")
            )
        }
    }

    private func statTile(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 36, height: 36)
                .background(Circle().fill(DS.accentTint))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(DS.title(.title2, .heavy))
                    .foregroundStyle(DS.ink)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(label)
                    .font(DS.sans(.footnote, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .dsCard(padding: 16)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Titres de section

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(DS.title(.title3, .heavy))
            .foregroundStyle(DS.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Par matière

    private var subjectsSection: some View {
        let subjects = Subject.allCases

        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle(languageManager.text("progress.subjects.title"))

            VStack(spacing: 0) {
                ForEach(Array(subjects.enumerated()), id: \.element) { index, subject in
                    SubjectProgressRow(subject: subject, xp: progressManager.xp(for: subject))
                    if index < subjects.count - 1 {
                        Rectangle()
                            .fill(DS.hairline)
                            .frame(height: 1)
                            .padding(.leading, 72)
                    }
                }
            }
            .dsCard(padding: 0)
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
        let p = progressManager.globalLevelProgress

        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle(languageManager.text("globalRank.title"))

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 16) {
                    GlobalRankRing(progress: p, size: 76)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(p.rank.localizedName(language: languageManager.current))
                            .font(DS.title(.title2, .heavy))
                            .foregroundStyle(DS.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(rankCaption(p))
                            .font(DS.sans(.subheadline, .medium))
                            .foregroundStyle(DS.inkSecondary)
                            .monospacedDigit()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)

                rankLadder(current: p.rank)
            }
            .dsCard()
        }
    }

    /// Les cinq rangs, du premier au dernier : ceux déjà atteints en plein, le rang en cours cerclé de safran.
    private func rankLadder(current: GlobalRank) -> some View {
        let ranks = GlobalRank.allCases
        let currentIndex = ranks.firstIndex(of: current) ?? 0

        return HStack(alignment: .top, spacing: 4) {
            ForEach(Array(ranks.enumerated()), id: \.element) { index, rank in
                let reached = index <= currentIndex
                VStack(spacing: 6) {
                    Image(systemName: rank.symbolName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(reached ? Color.white : DS.inkTertiary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(reached ? DS.accent : DS.surfaceMuted))
                        .overlay(
                            Circle().strokeBorder(index == currentIndex ? Self.saffron : Color.clear, lineWidth: 2.5)
                        )
                    Text(rank.localizedName(language: languageManager.current))
                        .font(DS.sans(.caption2, index == currentIndex ? .bold : .medium))
                        .foregroundStyle(reached ? DS.ink : DS.inkTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Quiz récents

    private var quizSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                sectionTitle(languageManager.text("progress.quizzes.title"))
                Spacer(minLength: 0)
                if store.isPremium && !progressManager.recentQuizzes.isEmpty {
                    Button {
                        hapticTrigger += 1
                        showAllQuizzes = true
                    } label: {
                        Text(languageManager.text("common.seeMoreArrow"))
                            .font(DS.sans(.subheadline, .bold))
                            .foregroundStyle(DS.accentSoft)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                }
            }

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
                                AnalyticsService.shared.pendingCourseOpenSource = .profile; selectedCourse = item.course
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
            shortcutIcon("questionmark", tint: DS.accent, background: DS.accentTint)

            VStack(alignment: .leading, spacing: 2) {
                Text(languageManager.text("profile.quiz.emptyTitle"))
                    .font(DS.title(.headline, .heavy))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(languageManager.text("profile.quiz.emptySubtitle"))
                    .font(DS.sans(.footnote, .medium))
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
        let bg: Color
        let title: String
        let subtitle: String
    }

    /// One of four states, resolved in plain statements: the tuple-returning closure this
    /// replaced was a type-checker sink.
    private var blockerCardState: BlockerCardState {
        let blocker = TikTokBlockerManager.shared
        if !store.isPremium {
            return BlockerCardState(
                icon: "lock.fill", tint: DS.accent, bg: DS.accentTint,
                title: languageManager.text("tiktokBlocker.card.premium.title"),
                subtitle: languageManager.text("tiktokBlocker.card.premium.subtitle")
            )
        }
        if !blocker.isArmed {
            return BlockerCardState(
                icon: "lock.fill", tint: DS.accent, bg: DS.accentTint,
                title: languageManager.text("tiktokBlocker.card.off.title"),
                subtitle: languageManager.text("tiktokBlocker.card.off.subtitle")
            )
        }
        if blocker.isUnlockWindowOpen {
            return BlockerCardState(
                icon: "checkmark.seal.fill", tint: DS.success, bg: DS.successTint,
                title: languageManager.text("tiktokBlocker.card.done.title"),
                subtitle: languageManager.text("tiktokBlocker.card.done.subtitle")
            )
        }
        let warmTint: Color = DS.warm.opacity(0.15)
        return BlockerCardState(
            icon: "lock.fill", tint: DS.warm, bg: warmTint,
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
                background: blockerState.bg,
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

            shortcutDivider

            shortcutRow(
                icon: "bookmark.fill",
                tint: DS.accent,
                background: DS.accentTint,
                title: languageManager.text("profile.favorites"),
                subtitle: String(format: languageManager.text("profile.favorites.count"), progressManager.favoriteCourses.count),
                trailingIcon: "chevron.forward"
            ) {
                showFavorites = true
            }

            shortcutDivider

            // « Partage Sophia · Offre 10 minutes de culture à un ami » : ouvre la feuille de partage.
            shortcutRow(
                icon: "paperplane.fill",
                tint: DS.accent,
                background: Self.saffron.opacity(0.22),
                title: languageManager.text("share.card.title"),
                subtitle: languageManager.text("share.card.subtitle"),
                trailingIcon: "square.and.arrow.up"
            ) {
                showShare = true
            }
        }
        .dsCard(padding: 0)
    }

    private var shortcutDivider: some View {
        Rectangle()
            .fill(DS.hairline)
            .frame(height: 1)
            .padding(.leading, 72)
    }

    private func shortcutIcon(_ systemName: String, tint: Color, background: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(background))
            .accessibilityHidden(true)
    }

    private func shortcutRow(
        icon: String,
        tint: Color,
        background: Color,
        title: String,
        subtitle: String,
        trailingIcon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            hapticTrigger += 1
            action()
        } label: {
            HStack(spacing: 14) {
                shortcutIcon(icon, tint: tint, background: background)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DS.title(.headline, .heavy))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(DS.sans(.footnote, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: trailingIcon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.inkTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(ProfileCardPress())
    }
}

// MARK: - Barre de progression animée

/// Barre fine qui se remplit à l'apparition (XP du niveau, XP d'une matière).
private struct ProgressPageBar: View {
    let fraction: Double
    var tint: Color = DS.accent
    var height: CGFloat = 8

    @State private var shown: Bool = false

    private var clamped: CGFloat { CGFloat(min(1, max(0, fraction))) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.hairline)
                Capsule()
                    .fill(tint)
                    .frame(width: shown ? max(clamped > 0 ? height : 0, geo.size.width * clamped) : 0)
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.5), value: fraction)
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.25)) {
                shown = true
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Ligne d'une matière

/// Une matière : pastille à sa couleur, nom, niveau, barre fine et XP restant avant le niveau suivant.
private struct SubjectProgressRow: View {
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

    private var progressLabel: String {
        let tier = currentTier
        if tier.level == ProgressManager.maxSubjectLevel {
            return String(format: languageManager.text("profile.progress.max"), xp)
        }
        let toNext = max(0, tier.upper - xp)
        return String(format: languageManager.text("profile.progress.toNext"), xp, toNext, tier.level + 1)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: subject.icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(subject.color)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(subject.color.opacity(0.16)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(subject.localizedShortName(language: languageManager.current))
                        .font(DS.title(.subheadline, .heavy))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    Text(String(format: languageManager.text("common.levelShort"), currentTier.level))
                        .font(DS.sans(.caption2, .bold))
                        .foregroundStyle(DS.accent)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(DS.accentTint))
                }

                ProgressPageBar(fraction: progressInLevel, tint: subject.color, height: 6)

                Text(progressLabel)
                    .font(DS.sans(.caption, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
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
                                        AnalyticsService.shared.pendingCourseOpenSource = .profile; selectedCourse = item.course
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
        .sophiaColorScheme()
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
        .sophiaColorScheme()
    }
}
