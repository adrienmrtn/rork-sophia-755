import SwiftUI

// MARK: - Phase enum used by CourseView to drive the end-of-course freemium flow.

nonisolated enum CourseEndPhase: Sendable {
    case none
    case completed
    case streak
}

// MARK: - Course Completed (full-screen celebration shown after the last slide in freemium)

struct CourseCompletedView: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let progressManager: ProgressManager
    /// XP for this subject BEFORE awarding the +10 course-completion bonus.
    let previousSubjectXP: Int
    /// XP awarded for finishing this course (typically +10, always granted).
    let earnedXP: Int
    /// Global XP reward result for finishing this course (+50 once per course).
    let globalAwardResult: GlobalXPAwardResult?
    /// Whether the locked freemium banner + Mini Quiz CTA are shown.
    let showFreemiumGate: Bool
    let onClose: () -> Void
    let onQuizTapped: () -> Void

    @State private var phase: EndFlowPhaseStep = .celebration
    @State private var appeared: Bool = false
    @State private var showTitle: Bool = false
    @State private var showCard: Bool = false
    @State private var showNote: Bool = false
    @State private var showButtons: Bool = false
    @State private var showLevelUp: Bool = false
    @State private var showGlobalRankUp: Bool = false
    @State private var thumbScale: CGFloat = 0.6
    @State private var displayedXP: Int = 0
    @State private var displayedLevel: Int = 1
    @State private var barFill: CGFloat = 0
    @State private var cachedThumb: UIImage?
    @State private var barFillStarted: Bool = false
    @State private var likeBurst: Int = 0

    private enum EndFlowPhaseStep {
        case celebration, progression, actions
    }

    private var currentSubjectXP: Int {
        progressManager.xp(for: course.subject)
    }

    private func tier(for xp: Int) -> (level: Int, lower: Int, upper: Int) {
        ProgressManager.subjectXPTiers.last(where: { xp >= $0.lower }) ?? ProgressManager.subjectXPTiers[0]
    }

    private var animatedXP: Int {
        displayedXP
    }

    private var startLevel: Int {
        tier(for: previousSubjectXP).level
    }

    private var endLevel: Int {
        tier(for: currentSubjectXP).level
    }

    private var didLevelUp: Bool {
        endLevel > startLevel
    }

    private var pendingGlobalRankUp: (previous: GlobalRank, new: GlobalRank, newLevel: Int)? {
        if let globalAwardResult, globalAwardResult.didRankUp {
            return (globalAwardResult.previousRank, globalAwardResult.newRank, globalAwardResult.newLevel)
        }
        return progressManager.pendingGlobalRankUp()
    }

    private func barFraction(for xp: Int) -> CGFloat {
        let t = tier(for: xp)
        if t.level == ProgressManager.maxSubjectLevel { return 1.0 }
        let span = max(1, t.upper - t.lower)
        return CGFloat(min(1.0, max(0.0, Double(xp - t.lower) / Double(span))))
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Spacers extensibles en haut et en bas : le groupe (vignette,
                            // titre, carte) est centré verticalement dans l'espace au-dessus
                            // des boutons, pour un équilibre haut / bas.
                            Spacer(minLength: 28)

                            thumbnail
                                .scaleEffect(thumbScale)
                                .opacity(appeared ? 1 : 0)

                            Spacer().frame(height: 22)

                            Text(languageManager.text("course.completed"))
                                .font(CourseType.font(26, .semibold, relativeTo: .title))
                                .foregroundStyle(DS.ink)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 24)
                                .opacity(showTitle ? 1 : 0)
                                .offset(y: showTitle ? 0 : 12)

                            if phase != .celebration {
                                progressionCard
                                    .padding(.horizontal, 24)
                                    .padding(.top, 18)
                                    .opacity(showCard ? 1 : 0)
                                    .offset(y: showCard ? 0 : 16)
                                    .transition(.opacity.combined(with: .offset(y: 16)))

                                socialRow
                                    .padding(.horizontal, 24)
                                    .padding(.top, 18)
                                    .opacity(showCard ? 1 : 0)
                                    .offset(y: showCard ? 0 : 16)
                                    .transition(.opacity.combined(with: .offset(y: 16)))
                            }

                            if showFreemiumGate && phase == .actions {
                                freemiumNote
                                    .padding(.horizontal, 24)
                                    .padding(.top, 18)
                                    .opacity(showNote ? 1 : 0)
                                    .offset(y: showNote ? 0 : 8)
                            }

                            Spacer(minLength: 28)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height)
                    }
                    .scrollIndicators(.hidden)
                }

                // Actions ancrées en bas de l'écran (plus de vide entre le CTA et le bas).
                if phase == .actions {
                    actionButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        .opacity(showButtons ? 1 : 0)
                        .offset(y: showButtons ? 0 : 12)
                }
            }
        }
        .fullScreenCover(isPresented: $showLevelUp) {
            LevelUpCelebrationView(
                subject: course.subject,
                previousLevel: startLevel,
                newLevel: endLevel,
                onContinue: {
                    showLevelUp = false
                    revealAfterSubjectLevelUp()
                }
            )
            .sophiaColorScheme()
        }
        .fullScreenCover(isPresented: $showGlobalRankUp) {
            if let pendingGlobalRankUp {
                GlobalRankUpCelebrationView(
                    previousRank: pendingGlobalRankUp.previous,
                    newRank: pendingGlobalRankUp.new,
                    newLevel: pendingGlobalRankUp.newLevel,
                    onContinue: {
                        progressManager.clearPendingGlobalRankUp()
                        showGlobalRankUp = false
                        revealActions()
                    }
                )
                .sophiaColorScheme()
            }
        }
        .sophiaColorScheme()
        .onAppear {
            cachedThumb = CourseImageMap.loadImage(for: course.id)
            displayedXP = previousSubjectXP
            displayedLevel = startLevel
            barFill = barFraction(for: previousSubjectXP)
            runOpeningSequence()
        }
    }

    private func runOpeningSequence() {
        // Phase 1 — celebration : la vignette se pose, la coche se dessine, le téléphone fête.
        Haptics.celebrate()
        withAnimation(DS.Motion.pop) {
            appeared = true
            thumbScale = 1.0
        }
        withAnimation(DS.Motion.reveal.delay(0.1)) {
            showTitle = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            phase = .progression
            withAnimation(DS.Motion.reveal) {
                showCard = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                animateProgression()
            }
        }
    }

    private func animateProgression() {
        guard !barFillStarted else { return }
        barFillStarted = true

        XPProgressAnimator.animate(
            from: previousSubjectXP,
            to: currentSubjectXP,
            setXP: { displayedXP = $0 },
            setLevel: { displayedLevel = $0 },
            setBarFill: { fill, animated in
                if animated {
                    barFill = fill
                } else {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { barFill = fill }
                }
            },
            haptic: {
                XPProgressAnimator.progressionHaptic(intensity: 0.5)
            },
            completion: {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                if didLevelUp {
                    showLevelUp = true
                } else if pendingGlobalRankUp != nil {
                    showGlobalRankUp = true
                } else {
                    revealActions()
                }
            }
        )
    }

    private func revealAfterSubjectLevelUp() {
        if pendingGlobalRankUp != nil {
            showGlobalRankUp = true
        } else {
            revealActions()
        }
    }

    private func revealActions() {
        phase = .actions
        if showFreemiumGate {
            withAnimation(.easeOut(duration: 0.5)) {
                showNote = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) {
                showButtons = true
            }
        }
    }

    // MARK: Thumbnail

    private var thumbnail: some View {
        ZStack {
            DS.accentTint
            if let img = cachedThumb {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .allowsHitTesting(false)
            } else {
                SubjectBadgeView(subject: course.subject, iconSize: 56, cornerRadius: 0)
            }
        }
        .frame(width: 152, height: 152)
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            // La coche verte se dessine une fois la vignette posée.
            DSCheckBadge(size: 34, delay: 0.3)
                .padding(3)
                .background(DS.surface, in: Circle())
                .offset(x: 8, y: 8)
        }
    }

    // MARK: Progression card

    private var progressionCard: some View {
        let tierNow = tier(for: animatedXP)
        let xpToNext = max(0, tierNow.upper - animatedXP)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                CourseSubjectAvatar(subject: course.subject, size: 36)

                Text(course.subject.localizedShortName(language: languageManager.current))
                    .font(DS.sans(.callout, .bold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2)

                Spacer(minLength: 8)

                Text(String(format: languageManager.text("common.levelShort"), displayedLevel))
                    .font(DS.sans(.caption, .heavy))
                    .foregroundStyle(DS.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DS.accentTint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            HStack(spacing: 4) {
                Text("\(displayedXP) XP")
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.ink)
                    .monospacedDigit()
                if tierNow.level < 5 {
                    Text(String(format: languageManager.text("common.xpBeforeNext"), xpToNext, tierNow.level + 1))
                        .font(DS.sans(.subheadline))
                        .foregroundStyle(DS.inkSecondary)
                        .monospacedDigit()
                }
            }

            CourseXPBar(fraction: Double(barFill), height: 8)

            CourseGoldPill(text: String(format: languageManager.text("common.xpEarned"), earnedXP))
        }
        .dsCard(padding: 16)
    }

    // MARK: Aimer le cours, suivre le créateur

    private var author: CourseAuthor? { CreatorIdentity.forCourse(course.id).author }

    /// Le fond d'un bouton de la rangée « aimer / suivre » : carte bordée avec son rebord bas.
    private func socialChrome(fill: Color, border: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
        return shape
            .fill(fill)
            .overlay(shape.strokeBorder(border, lineWidth: 1.5))
            .background(shape.fill(border).offset(y: 1.5))
    }

    /// Deux gestes à chaud, juste après la lecture : le cœur sur le cours, et l'abonnement au
    /// créateur. Rapportés avec l'écran `course_end`.
    private var socialRow: some View {
        HStack(spacing: 10) {
            likeButton
            if let author {
                followButton(author)
            }
        }
    }

    private var likeButton: some View {
        let liked = progressManager.isLiked(course.id)
        return Button {
            Haptics.select()
            progressManager.toggleLike(course.id)
            if !liked { likeBurst += 1 }
            AnalyticsService.shared.log(liked ? .unlike : .like, courseId: course.id, screen: "course_end")
        } label: {
            HStack(spacing: 8) {
                LikeHeartIcon(liked: liked, burst: likeBurst, size: 17, idleTint: DS.liked)
                Text(languageManager.text(liked ? "course.end.liked" : "course.end.like"))
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(liked ? DS.liked : DS.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                socialChrome(
                    fill: liked ? DS.liked.opacity(0.1) : DS.surface,
                    border: liked ? DS.liked.opacity(0.55) : DS.hairline
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(haptic: false))
        .animation(DS.Motion.snappy, value: liked)
        .accessibilityLabel(Text(languageManager.text(liked ? "common.unlike" : "common.like")))
    }

    private func followButton(_ author: CourseAuthor) -> some View {
        let following = progressManager.isFollowing(author.slug)
        let firstName = author.name.split(separator: " ").first.map(String.init) ?? author.name
        return Button {
            Haptics.select()
            progressManager.toggleFollow(author.slug)
            AnalyticsService.shared.log(following ? .unfollow : .follow, courseId: course.id, screen: "course_end", props: ["creator": .string(author.slug)])
        } label: {
            HStack(spacing: 8) {
                AuthorAvatarView(author: author, size: 24)
                Text(following ? languageManager.text("creator.following") : String(format: languageManager.text("course.end.follow"), firstName))
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(following ? DS.accent : DS.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                socialChrome(
                    fill: following ? DS.accentTint : DS.surface,
                    border: following ? DS.accent : DS.hairline
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(haptic: false))
        .animation(DS.Motion.snappy, value: following)
        .accessibilityLabel(Text(following ? languageManager.text("creator.following") : languageManager.text("creator.follow")))
    }

    // MARK: Freemium note

    private var freemiumNote: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.accent)
            Text(languageManager.text("course.dailyFreeDone"))
                .font(DS.sans(.footnote, .bold))
                .foregroundStyle(DS.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(DS.accentTint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Action buttons (X close · Mini Quiz)

    // Les deux boutons vibrent par leur style.
    private var actionButtons: some View {
        HStack(spacing: 10) {
            // X close
            Button {
                onClose()
            } label: {
                CourseRoundIcon(systemName: "xmark")
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(Text(languageManager.text("common.close")))

            // Mini Quiz
            Button {
                onQuizTapped()
            } label: {
                HStack(spacing: 8) {
                    if showFreemiumGate {
                        Image(systemName: "lock")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text(languageManager.text("common.miniQuiz"))
                    Image(systemName: "arrow.forward")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
        }
    }
}

// MARK: - Streak Celebration screen

/// La série : la flamme safran qui oscille, le nombre de jours qui arrive avec un compteur,
/// puis la semaine en pastilles qui apparaissent en cascade.
struct StreakCelebrationView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let streak: Int
    let subject: Subject
    let lastActiveDate: String?
    let onReturnHome: () -> Void

    @State private var appeared: Bool = false
    @State private var flameScale: CGFloat = 0.5
    @State private var numberAppeared: Bool = false
    /// La valeur vers laquelle le compteur défile : 0, puis la série.
    @State private var countTarget: Int = 0
    @State private var confetti = false

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                GeometryReader { geo in
                    ScrollView {
                        streakSummary
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: geo.size.height)
                    }
                    .scrollIndicators(.hidden)
                }

                // Vibre par son style.
                Button {
                    onReturnHome()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "house")
                            .font(.subheadline.weight(.semibold))
                        Text(languageManager.text("common.backHome"))
                    }
                }
                .buttonStyle(DSPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
            }

            if confetti {
                PathConfettiBurst(
                    colors: [CoursePalette.gold, CoursePalette.goldTint, DS.accent, DS.accentTint],
                    pieceCount: 60,
                    duration: 2.6,
                    origin: CGPoint(x: 0.5, y: 0.3)
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onAppear { runSequence() }
    }

    private var streakSummary: some View {
        VStack(spacing: 14) {
            DSFlame(size: 84)
                .scaleEffect(flameScale)

            DSCountUp(
                value: countTarget,
                duration: 0.9,
                font: CourseType.font(96, .heavy, relativeTo: .largeTitle),
                color: DS.ink
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .scaleEffect(numberAppeared ? 1 : 0.6)
            .opacity(numberAppeared ? 1 : 0)
            .accessibilityLabel(Text("\(streak)"))

            Text(streak <= 1 ? languageManager.text("course.streak.day") : languageManager.text("course.streak.days"))
                .font(CourseType.font(22, .semibold, relativeTo: .title2))
                .foregroundStyle(DS.ink)
                .opacity(numberAppeared ? 1 : 0)

            Text(String(format: languageManager.text("course.streak.message"), subject.localizedShortName(language: languageManager.current)))
                .font(DS.sans(.callout))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(appeared ? 1 : 0)

            weekStrip
                .padding(.top, 10)

            Text(languageManager.text("course.streak.onTrack"))
                .font(DS.sans(.callout, .bold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
                .opacity(appeared ? 1 : 0)
        }
    }

    private func runSequence() {
        if reduceMotion {
            // Pas de mouvement : tout est posé d'emblée, le compteur seul défile.
            flameScale = 1
            numberAppeared = true
            appeared = true
            countTarget = streak
            Haptics.celebrate()
            return
        }

        withAnimation(DS.Motion.pop.delay(0.05)) {
            flameScale = 1.0
        }
        withAnimation(DS.Motion.pop.delay(0.25)) {
            numberAppeared = true
        }
        // Le compteur part une fois le chiffre visible ; il vibre par petits crans (`DSCountUp`).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            countTarget = streak
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.6)) {
            appeared = true
        }
        // Le compteur est arrivé : la récompense, et une pluie de confettis.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            Haptics.celebrate()
            confetti = true
        }
    }

    private var weekStrip: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayLetters = languageManager.current.mondayFirstWeekdayLetters

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        // La première case est le premier jour de la série, pas le lundi.
        let firstDay = StreakWeek.firstDay(streak: streak, lastActive: lastActiveDate, today: today, calendar: calendar)

        return HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { i in
                let date = calendar.date(byAdding: .day, value: i, to: firstDay) ?? today
                let isToday = calendar.isDate(date, inSameDayAs: today)
                let isFuture = date > today
                let dateStr = fmt.string(from: date)

                let isDone: Bool = {
                    guard let last = lastActiveDate,
                          let lastDate = fmt.date(from: last) else { return false }
                    let daysFromLast = calendar.dateComponents([.day], from: date, to: lastDate).day ?? 999
                    if isFuture { return false }
                    return dateStr <= last && daysFromLast >= 0 && daysFromLast < streak
                }()

                // Les pastilles arrivent en cascade ; la coche de chaque jour fait se dessine à la suite.
                StreakDayPill(
                    letter: dayLetters[StreakWeek.letterIndex(of: date, calendar: calendar)],
                    isDone: isDone,
                    isToday: isToday,
                    isFuture: isFuture,
                    checkDelay: 0.95 + Double(i) * 0.07
                )
                .dsStagger(i, step: 0.07, base: 0.75, offset: 10)
            }
        }
    }
}

/// Un jour de la semaine de la série : pastille dorée cochée s'il est fait, cerclée d'or si
/// c'est aujourd'hui, simplement cerclée sinon ; l'initiale du jour dessous.
private struct StreakDayPill: View {
    let letter: String
    let isDone: Bool
    let isToday: Bool
    let isFuture: Bool
    let checkDelay: Double

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if isDone {
                    DSCheckBadge(size: 36, fill: CoursePalette.gold, delay: checkDelay)
                } else {
                    Circle().fill(DS.surface)
                    Circle().strokeBorder(
                        isToday ? CoursePalette.gold : DS.ink.opacity(0.2),
                        lineWidth: isToday ? 2.5 : 1.5
                    )
                }
            }
            .frame(width: 36, height: 36)
            .opacity(isFuture ? 0.6 : 1)

            Text(letter)
                .font(DS.sans(.caption, .bold))
                .foregroundStyle(DS.ink)
        }
        .frame(width: 36)
    }
}
