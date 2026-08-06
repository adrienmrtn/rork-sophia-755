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

                            Spacer().frame(height: 18)

                            Text(languageManager.text("course.completed"))
                                .font(DS.title(.largeTitle, .semibold))
                                .foregroundStyle(DS.ink)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .opacity(showTitle ? 1 : 0)
                                .offset(y: showTitle ? 0 : 12)

                            if phase != .celebration {
                                progressionCard
                                    .padding(.horizontal, 20)
                                    .padding(.top, 22)
                                    .opacity(showCard ? 1 : 0)
                                    .offset(y: showCard ? 0 : 16)
                                    .transition(.opacity.combined(with: .offset(y: 16)))
                            }

                            if showFreemiumGate && phase == .actions {
                                freemiumNote
                                    .padding(.horizontal, 20)
                                    .padding(.top, 14)
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
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
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
            }
        }
        .onAppear {
            cachedThumb = CourseImageMap.loadImage(for: course.id)
            displayedXP = previousSubjectXP
            displayedLevel = startLevel
            barFill = barFraction(for: previousSubjectXP)
            runOpeningSequence()
        }
    }

    private func runOpeningSequence() {
        // Phase 1 — celebration
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
            appeared = true
            thumbScale = 1.0
            showTitle = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            phase = .progression
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) {
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
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.jakarta(size: 26, weight: .regular))
                .foregroundStyle(DS.accent)
                .background(Circle().fill(.white).frame(width: 26, height: 26))
                .offset(x: 6, y: 6)
        }
    }

    // MARK: Progression card

    private var progressionCard: some View {
        let tierNow = tier(for: animatedXP)
        let xpToNext = max(0, tierNow.upper - animatedXP)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                SubjectBadgeView(subject: course.subject, iconSize: 22, cornerRadius: 10)
                    .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(course.subject.localizedShortName(language: languageManager.current))
                        .font(DS.title(.headline, .semibold))
                        .foregroundStyle(DS.ink)
                    HStack(spacing: 4) {
                        Text("\(displayedXP) XP")
                            .font(DS.sans(.caption, .medium))
                            .foregroundStyle(DS.inkSecondary)
                            .monospacedDigit()
                        if tierNow.level < 5 {
                            Text(String(format: languageManager.text("common.xpBeforeNext"), xpToNext, tierNow.level + 1))
                                .font(DS.sans(.caption, .medium))
                                .foregroundStyle(DS.inkTertiary)
                        }
                    }
                }
                Spacer()
                Text(String(format: languageManager.text("common.levelShort"), displayedLevel))
                    .font(DS.sans(.caption2, .semibold))
                    .foregroundStyle(DS.accentSoft)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DS.accentTint, in: Capsule())
            }

            CalmProgressBar(fraction: Double(barFill), height: 8)

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.jakarta(size: 10, weight: .medium))
                Text(String(format: languageManager.text("common.xpEarned"), earnedXP))
                    .font(DS.sans(.caption, .semibold))
            }
            .foregroundStyle(DS.accentSoft)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DS.accentTint, in: Capsule())
        }
        .dsCard()
    }

    // MARK: Freemium note

    private var freemiumNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.jakarta(size: 13, weight: .medium))
            Text(languageManager.text("course.dailyFreeDone"))
                .font(DS.sans(.subheadline, .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(DS.accentSoft)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(DS.accentTint, in: Capsule())
    }

    // MARK: Action buttons (X close · Mini Quiz)

    private var actionButtons: some View {
        HStack(spacing: 14) {
            // X close
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.jakarta(size: 16, weight: .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 56, height: 56)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }
            .buttonStyle(SoftPressButtonStyle())

            // Mini Quiz
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onQuizTapped()
            } label: {
                HStack(spacing: 8) {
                    if showFreemiumGate {
                        Image(systemName: "lock.fill")
                            .font(.jakarta(size: 13, weight: .medium))
                    }
                    Text(languageManager.text("common.miniQuiz"))
                    Image(systemName: "arrow.right")
                        .font(.jakarta(size: 13, weight: .medium))
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
        }
    }
}

// MARK: - Streak Celebration screen

struct StreakCelebrationView: View {
    @Environment(LanguageManager.self) private var languageManager
    let streak: Int
    let subject: Subject
    let lastActiveDate: String?
    let onReturnHome: () -> Void

    @State private var appeared: Bool = false
    @State private var flameScale: CGFloat = 0.5
    @State private var numberAppeared: Bool = false
    @State private var displayedStreak: Int = 0

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Blocs équilibrés entre le haut de l'écran et le bouton ancré en bas.
                            Spacer(minLength: 16)

                            flameView
                                .scaleEffect(flameScale)

                            Spacer(minLength: 8)

                            VStack(spacing: 4) {
                                Text("\(displayedStreak)")
                                    .font(.jakarta(size: 72, weight: .semibold))
                                    .foregroundStyle(DS.ink)
                                    .contentTransition(.numericText())
                                    .scaleEffect(numberAppeared ? 1 : 0.6)
                                    .opacity(numberAppeared ? 1 : 0)

                                Text(streak <= 1 ? languageManager.text("course.streak.day") : languageManager.text("course.streak.days"))
                                    .font(DS.title(.title3, .semibold))
                                    .foregroundStyle(DS.ink)
                                    .opacity(numberAppeared ? 1 : 0)
                            }

                            Text(String(format: languageManager.text("course.streak.message"), subject.localizedShortName(language: languageManager.current)))
                                .font(DS.sans(.subheadline))
                                .foregroundStyle(DS.inkSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.top, 12)
                                .opacity(appeared ? 1 : 0)

                            Spacer(minLength: 22)

                            weekStrip
                                .padding(.horizontal, 22)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 10)

                            Spacer(minLength: 18)

                            Text(languageManager.text("course.streak.onTrack"))
                                .font(DS.title(.headline, .semibold))
                                .foregroundStyle(DS.ink)
                                .opacity(appeared ? 1 : 0)

                            Spacer(minLength: 20)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height)
                    }
                    .scrollIndicators(.hidden)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onReturnHome()
                } label: {
                    HStack(spacing: 8) {
                        Text(languageManager.text("common.backHome"))
                        Image(systemName: "house.fill")
                            .font(.jakarta(size: 13, weight: .medium))
                    }
                }
                .buttonStyle(DSPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
            }
        }
        .onAppear {
            displayedStreak = max(0, streak - 1)

            withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.05)) {
                flameScale = 1.0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.3)) {
                numberAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.snappy) { displayedStreak = streak }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.55)) {
                appeared = true
            }
        }
    }

    private var flameView: some View {
        ZStack {
            Circle()
                .fill(DS.accentTint)
                .frame(width: 128, height: 128)

            Image(systemName: "flame.fill")
                .font(.jakarta(size: 60, weight: .regular))
                .foregroundStyle(DS.accent)
        }
        .frame(height: 128)
    }

    private var weekStrip: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayLetters = languageManager.current.mondayFirstWeekdayLetters
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = ((weekday + 5) % 7)
        let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) ?? today

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        return HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { i in
                let date = calendar.date(byAdding: .day, value: i, to: monday) ?? today
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

                VStack(spacing: 6) {
                    Text(dayLetters[i])
                        .font(DS.sans(.caption2, .medium))
                        .foregroundStyle(DS.inkTertiary)
                    ZStack {
                        if isDone {
                            Circle().fill(DS.accent)
                            Image(systemName: "checkmark")
                                .font(.jakarta(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                        } else if isToday {
                            Circle().fill(DS.surface)
                            Circle().strokeBorder(DS.accentSoft, lineWidth: 2)
                        } else {
                            Circle().fill(DS.surfaceMuted)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .opacity(isFuture ? 0.5 : 1)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
