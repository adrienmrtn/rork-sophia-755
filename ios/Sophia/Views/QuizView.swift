import SwiftUI

struct QuizView: View {
    let course: Course
    let progressManager: ProgressManager
    var initialCollectionEvents: [CollectionProgressEvent] = []
    var initialCardCandidates: [CollectibleCard] = []
    let onReturnHome: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var currentQuestionIndex: Int = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var hasAnswered: Bool = false
    @State private var correctCount: Int = 0
    @State private var isFinished: Bool = false
    @State private var showFeedback: Bool = false
    @State private var showXPProgress: Bool = false
    @State private var showStreak: Bool = false
    @State private var confettiTrigger: Int = 0
    @State private var streakBefore: Int = 0
    @State private var completedBefore: Int = 0
    @State private var subjectXPBefore: Int = 0
    @State private var resultAppeared: Bool = false
    @State private var trophyBounce: Int = 0
    @State private var scoreAnimated: Int = 0
    @State private var starsRevealed: Int = 0
    @State private var ringProgress: CGFloat = 0
    @State private var xpScreenAppeared: Bool = false
    @State private var xpBarAnimated: Bool = false
    @State private var xpBarFill: CGFloat = 0
    @State private var displayedXP: Int = 0
    @State private var xpButtonAppeared: Bool = false
    @State private var levelUpBounce: Int = 0
    @State private var glowPulse: Bool = false
    @State private var showLevelUpCelebration: Bool = false
    @State private var showGlobalRankUpCelebration: Bool = false
    @State private var xpBarShimmer: CGFloat = -80
    @State private var xpBarShimmerActive: Bool = false
    @State private var cachedCourseThumb: UIImage?
    @State private var shuffledQuestions: [ShuffledQuestion] = []
    @State private var questionAppeared: Bool = false
    @State private var comboCount: Int = 0
    @State private var showCombo: Bool = false
    @State private var xpEarned: Int = 0
    @State private var showXPPopup: Bool = false
    @State private var popupXPAmount: Int = 0
    @State private var globalQuizAwardResult: GlobalXPAwardResult?
    @State private var pendingCardCandidates: [CollectibleCard] = []
    @State private var currentCardUnlockEvent: CardUnlockEvent?
    @State private var showCardUnlock: Bool = false
    @State private var showCardRankUp: Bool = false
    @State private var courseWasCompletedBeforeQuiz: Bool = false
    @State private var pendingCollectionEvents: [CollectionProgressEvent] = []
    @State private var currentCollectionEvent: CollectionProgressEvent?
    @State private var collectionCompletionAwardResult: GlobalXPAwardResult?
    @State private var showCollectionProgress: Bool = false
    @State private var showCollectionCompleted: Bool = false
    @State private var showCollectionRankUp: Bool = false

    /// Fixed XP bonus awarded when the quiz is fully completed.
    private let quizCompletionXPBonus: Int = 10

    // Neo-brutalist palette
    private let ink = Color.black
    private let cream = Color(red: 0.984, green: 0.961, blue: 0.918)
    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)
    private let mint = Color(red: 0.70, green: 0.95, blue: 0.80)
    private let coral = Color(red: 1.0, green: 0.55, blue: 0.55)
    private let yellow = Color(red: 1.0, green: 0.84, blue: 0.35)
    private let orange = Color(red: 1.0, green: 0.55, blue: 0.18)

    private var pastel: Color {
        switch course.subject {
        case .histoire: return Color(red: 1.0, green: 0.86, blue: 0.62)
        case .sciences: return Color(red: 0.70, green: 0.95, blue: 0.80)
        case .litterature: return Color(red: 1.0, green: 0.78, blue: 0.78)
        case .art: return Color(red: 0.66, green: 0.92, blue: 0.96)
        case .mythologie: return Color(red: 0.82, green: 0.78, blue: 1.0)
        case .comprendreLeMonde: return Color(red: 0.74, green: 0.90, blue: 1.0)
        }
    }

    private var currentQuestion: ShuffledQuestion {
        shuffledQuestions[currentQuestionIndex]
    }

    private var isCorrect: Bool {
        selectedOptionIndex == currentQuestion.correctIndex
    }

    private var progressValue: Double {
        Double(currentQuestionIndex + 1) / Double(shuffledQuestions.count)
    }

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            if showStreak {
                StreakCelebrationView(
                    streak: progressManager.streak,
                    subject: course.subject,
                    lastActiveDate: progressManager.progress.lastActiveDate,
                    onReturnHome: { onReturnHome() }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if showXPProgress {
                xpProgressionView
                    .transition(.opacity)
            } else if isFinished {
                resultView
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else if !shuffledQuestions.isEmpty {
                questionView
            }

            if showXPPopup {
                xpPopupView
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .fullScreenCover(isPresented: $showLevelUpCelebration) {
            LevelUpCelebrationView(
                subject: course.subject,
                previousLevel: levelBefore,
                newLevel: levelAfter,
                onContinue: {
                    showLevelUpCelebration = false
                    revealAfterSubjectLevelUp()
                }
            )
        }
        .fullScreenCover(isPresented: $showGlobalRankUpCelebration) {
            if let pendingGlobalRankUp {
                GlobalRankUpCelebrationView(
                    previousRank: pendingGlobalRankUp.previous,
                    newRank: pendingGlobalRankUp.new,
                    newLevel: pendingGlobalRankUp.newLevel,
                    onContinue: {
                        progressManager.clearPendingGlobalRankUp()
                        globalQuizAwardResult = nil
                        showGlobalRankUpCelebration = false
                        revealXPContinueButton()
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showCardUnlock) {
            if let currentCardUnlockEvent {
                CardUnlockCelebrationView(event: currentCardUnlockEvent) {
                    showCardUnlock = false
                    self.currentCardUnlockEvent = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        continueAfterQuizCompletion()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCardRankUp) {
            if let pending = progressManager.pendingGlobalRankUp() {
                GlobalRankUpCelebrationView(
                    previousRank: pending.previous,
                    newRank: pending.new,
                    newLevel: pending.newLevel,
                    onContinue: {
                        progressManager.clearPendingGlobalRankUp()
                        showCardRankUp = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            continueAfterQuizCompletion()
                        }
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showCollectionProgress) {
            if let currentCollectionEvent {
                CollectionProgressCelebrationView(event: currentCollectionEvent) {
                    showCollectionProgress = false
                    if currentCollectionEvent.didCompleteCollection {
                        collectionCompletionAwardResult = progressManager.awardGlobalXP(
                            reason: .collectionCompleted(id: currentCollectionEvent.collection.id),
                            amount: progressManager.collectionCompletionXP(for: currentCollectionEvent.collection)
                        )
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            showCollectionCompleted = true
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            continueAfterQuizCompletion()
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCollectionCompleted) {
            if let currentCollectionEvent {
                CollectionCompletedCelebrationView(
                    event: currentCollectionEvent,
                    awardedXP: collectionCompletionAwardResult?.awardedXP ?? 0,
                    onContinue: {
                        showCollectionCompleted = false
                        if collectionCompletionAwardResult?.didRankUp == true || progressManager.pendingGlobalRankUp() != nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                showCollectionRankUp = true
                            }
                        } else {
                            collectionCompletionAwardResult = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                continueAfterQuizCompletion()
                            }
                        }
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showCollectionRankUp) {
            if let pending = progressManager.pendingGlobalRankUp() {
                GlobalRankUpCelebrationView(
                    previousRank: pending.previous,
                    newRank: pending.new,
                    newLevel: pending.newLevel,
                    onContinue: {
                        progressManager.clearPendingGlobalRankUp()
                        collectionCompletionAwardResult = nil
                        showCollectionRankUp = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            continueAfterQuizCompletion()
                        }
                    }
                )
            }
        }
        .onAppear {
            streakBefore = progressManager.streak
            completedBefore = progressManager.completedCount
            subjectXPBefore = progressManager.xp(for: course.subject)
            courseWasCompletedBeforeQuiz = progressManager.courseStatus(for: course.id) == .completed
            pendingCollectionEvents = initialCollectionEvents
            pendingCardCandidates = initialCardCandidates
            shuffleAllQuestions()
        }
    }

    private func shuffleAllQuestions() {
        shuffledQuestions = course.quiz.map { q in
            var indexedOptions = q.options.enumerated().map { ($0.offset, $0.element) }
            indexedOptions.shuffle()
            let newCorrectIndex = indexedOptions.firstIndex(where: { $0.0 == q.correctIndex }) ?? 0
            return ShuffledQuestion(
                question: q.question,
                options: indexedOptions.map(\.1),
                correctIndex: newCorrectIndex,
                explanation: q.explanation
            )
        }
        questionAppeared = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                questionAppeared = true
            }
        }
    }

    private var questionView: some View {
        VStack(spacing: 0) {
            quizHeader
            brutalProgressBar

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    questionCard
                        .opacity(questionAppeared ? 1 : 0)
                        .offset(y: questionAppeared ? 0 : 20)
                        .padding(.top, 20)

                    VStack(spacing: 14) {
                        ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                            brutalOptionButton(index: index, text: option)
                                .opacity(questionAppeared ? 1 : 0)
                                .offset(y: questionAppeared ? 0 : CGFloat(20 + index * 8))
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08),
                                    value: questionAppeared
                                )
                        }
                    }
                    .id("options_\(currentQuestionIndex)")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, showFeedback ? 260 : 40)
            }
            .scrollIndicators(.hidden)

            if showFeedback {
                brutalFeedbackBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var questionCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ink)
                .offset(y: 6)
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Text(course.subject.emoji)
                        .font(.system(size: 14))
                    Text(course.subject.shortName.uppercased())
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                        .tracking(0.5)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ink, in: Capsule())

                Text(currentQuestion.question)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id("question_\(currentQuestionIndex)")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(pastel)
            .clipShape(.rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(ink, lineWidth: 3)
            }
        }
    }

    private var brutalProgressBar: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ink)
                    .frame(height: 18)
                    .offset(y: 4)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white)
                            .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                            .frame(height: 18)
                        Capsule()
                            .fill(pink)
                            .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                            .frame(width: max(geo.size.width * progressValue, 18), height: 18)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progressValue)
                    }
                }
                .frame(height: 18)
            }
            .padding(.bottom, 4)

            if showCombo && comboCount >= 2 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(ink)
                    Text("x\(comboCount)")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(yellow, in: Capsule())
                .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var quizHeader: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(.subheadline, weight: .heavy))
                    .foregroundStyle(ink)
                    .frame(width: 40, height: 40)
                    .background(Color.white, in: Circle())
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
            }

            Spacer()

            Text("\(currentQuestionIndex + 1) / \(shuffledQuestions.count)")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(ink, in: Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private func brutalOptionButton(index: Int, text: String) -> some View {
        Button {
            guard !hasAnswered else { return }
            selectedOptionIndex = index
            hasAnswered = true
            if index == currentQuestion.correctIndex {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                correctCount += 1
                comboCount += 1
                let xp = comboCount >= 3 ? 3 : (comboCount >= 2 ? 2 : 1)
                xpEarned += xp
                progressManager.addXP(subject: course.subject, amount: xp)
                showXPBubble(xp: xp)
                if comboCount >= 2 {
                    withAnimation(.spring(response: 0.3)) {
                        showCombo = true
                    }
                }
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                comboCount = 0
                withAnimation(.spring(response: 0.3)) {
                    showCombo = false
                }
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showFeedback = true
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ink)
                    .offset(y: 5)
                HStack(spacing: 14) {
                    Text("\(Character(UnicodeScalar(65 + index)!))")
                        .font(.system(.title3, design: .rounded, weight: .black))
                        .foregroundStyle(optionLetterFg(for: index))
                        .frame(width: 42, height: 42)
                        .background(optionLetterBg(for: index))
                        .clipShape(.rect(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(ink, lineWidth: 2.5)
                        }

                    Text(text)
                        .font(.system(.body, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    optionTrailingIcon(for: index)
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(minHeight: 76)
                .background(optionCardBg(for: index))
                .clipShape(.rect(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(ink, lineWidth: 3)
                }
                .offset(y: hasAnswered && index == selectedOptionIndex ? 3 : 0)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasAnswered)
    }

    private func optionCardBg(for index: Int) -> Color {
        guard hasAnswered else { return Color.white }
        if index == currentQuestion.correctIndex { return mint }
        if index == selectedOptionIndex, index != currentQuestion.correctIndex { return coral }
        return Color.white
    }

    private func optionLetterFg(for index: Int) -> Color {
        ink
    }

    private func optionLetterBg(for index: Int) -> some ShapeStyle {
        if hasAnswered,
           index == currentQuestion.correctIndex || (index == selectedOptionIndex && index != currentQuestion.correctIndex) {
            return AnyShapeStyle(Color.white)
        }
        return AnyShapeStyle(yellow)
    }

    @ViewBuilder
    private func optionTrailingIcon(for index: Int) -> some View {
        if hasAnswered && index == currentQuestion.correctIndex {
            Image(systemName: "checkmark")
                .font(.system(.headline, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(mint, in: Circle())
                .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                .transition(.scale.combined(with: .opacity))
        } else if hasAnswered && index == selectedOptionIndex && !isCorrect {
            Image(systemName: "xmark")
                .font(.system(.headline, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(coral, in: Circle())
                .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                .transition(.scale.combined(with: .opacity))
        } else {
            Color.clear
                .frame(width: 32, height: 32)
        }
    }

    private func showXPBubble(xp: Int) {
        popupXPAmount = xp
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            showXPPopup = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.35)) {
                showXPPopup = false
            }
        }
    }

    private var xpPopupView: some View {
        VStack {
            Spacer()
                .frame(height: 100)
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(ink)
                Text("+\(popupXPAmount) XP")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(yellow, in: Capsule())
            .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
            .background(alignment: .top) {
                Capsule()
                    .fill(ink)
                    .offset(y: 3)
            }
            .padding(.bottom, 3)
            Spacer()
        }
        .allowsHitTesting(false)
    }

    private var brutalFeedbackBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(ink)
                .frame(height: 3)

            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(ink)
                            .offset(y: 4)
                            .frame(width: 56, height: 56)
                        Circle()
                            .fill(isCorrect ? mint : coral)
                            .frame(width: 56, height: 56)
                            .overlay { Circle().strokeBorder(ink, lineWidth: 3) }
                        Image(systemName: isCorrect ? "checkmark" : "xmark")
                            .font(.title2.weight(.black))
                            .foregroundStyle(ink)
                            .symbolEffect(.bounce, value: showFeedback)
                    }
                    .frame(width: 56, height: 60, alignment: .top)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isCorrect ? (comboCount >= 3 ? "Incroyable !" : comboCount >= 2 ? "Excellent !" : "Bonne réponse !") : "Pas tout à fait...")
                            .font(.system(.title3, design: .rounded, weight: .black))
                            .foregroundStyle(ink)
                        if isCorrect, comboCount >= 2 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption.weight(.heavy))
                                Text("Combo x\(comboCount)")
                                    .font(.system(.caption, design: .rounded, weight: .heavy))
                            }
                            .foregroundStyle(ink)
                        }

                        if !currentQuestion.explanation.isEmpty {
                            Text(currentQuestion.explanation)
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(ink.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 4)
                        }
                    }

                    Spacer()
                }

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    nextQuestion()
                } label: {
                    HStack(spacing: 8) {
                        Text("Continuer")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.heavy))
                    }
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(BrutalPillStyle(fill: isCorrect ? mint : pink))
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 20)
            .background(
                (isCorrect ? mint.opacity(0.35) : coral.opacity(0.35))
                    .background(cream)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private func nextQuestion() {
        if currentQuestionIndex < shuffledQuestions.count - 1 {
            withAnimation(.easeOut(duration: 0.2)) {
                showFeedback = false
                questionAppeared = false
            }
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                selectedOptionIndex = nil
                hasAnswered = false
                currentQuestionIndex += 1
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    questionAppeared = true
                }
            }
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                showFeedback = false
            }
            // Award the fixed quiz-completion XP bonus once, before transitioning to the result screen.
            progressManager.addXP(subject: course.subject, amount: quizCompletionXPBonus)
            xpEarned += quizCompletionXPBonus
            globalQuizAwardResult = progressManager.awardGlobalXP(
                reason: .quizCompleted(courseId: course.id),
                amount: ProgressManager.globalQuizCompletionXP
            )
            let cardCandidates = courseWasCompletedBeforeQuiz ? [] : progressManager.cardUnlockCandidates(forCompletingCourseId: course.id)
            progressManager.completeCourse(courseId: course.id, quizScore: correctCount, completedQuiz: true)
            if !courseWasCompletedBeforeQuiz {
                pendingCardCandidates = cardCandidates
                pendingCollectionEvents = progressManager.collectionProgressEvents(forNewlyCompletedCourseId: course.id)
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFinished = true
            }
        }
    }


    private var resultView: some View {
        ZStack {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                // Trophy plate — yellow card with black border + offset
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(ink)
                        .frame(width: 200, height: 200)
                        .offset(y: 8)
                    ZStack {
                        Circle()
                            .fill(yellow)
                            .frame(width: 200, height: 200)
                            .overlay { Circle().strokeBorder(ink, lineWidth: 3.5) }

                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(ink, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 170, height: 170)
                            .rotationEffect(.degrees(-90))

                        Image(systemName: "trophy.fill")
                            .font(.system(size: 70, weight: .black))
                            .foregroundStyle(ink)
                            .symbolEffect(.bounce, value: trophyBounce)
                            .scaleEffect(glowPulse ? 1.05 : 1.0)
                    }
                    .scaleEffect(resultAppeared ? 1 : 0.3)
                    .opacity(resultAppeared ? 1 : 0)
                }
                .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1), value: resultAppeared)

                VStack(spacing: 10) {
                    Text("Bravo, quiz terminé !")
                        .font(.system(.title, design: .rounded, weight: .black))
                        .foregroundStyle(ink)
                        .opacity(resultAppeared ? 1 : 0)
                        .offset(y: resultAppeared ? 0 : 15)
                        .animation(.spring(response: 0.5).delay(0.3), value: resultAppeared)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(scoreAnimated)")
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundStyle(ink)
                            .contentTransition(.numericText(countsDown: false))
                        Text("/ \(shuffledQuestions.count)")
                            .font(.system(.title2, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.5))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.white, in: .rect(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(ink, lineWidth: 3)
                    }
                    .opacity(resultAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.5), value: resultAppeared)

                    Text("bonnes réponses")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink.opacity(0.65))
                        .opacity(resultAppeared ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.6), value: resultAppeared)

                    if xpEarned > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(ink)
                            Text("+\(xpEarned) XP")
                                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                                .foregroundStyle(ink)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(yellow, in: Capsule())
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                        .scaleEffect(resultAppeared ? 1 : 0.5)
                        .opacity(resultAppeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.8), value: resultAppeared)
                    }
                }

                animatedScoreStars

                Spacer()

                VStack(spacing: 14) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showXPProgress = true
                        }
                        startXPProgressionSequence()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "house.fill")
                            Text("Retour à l'accueil")
                        }
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    }
                    .buttonStyle(BrutalPillStyle(fill: pink))

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        resetQuiz()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Refaire le quiz")
                        }
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    }
                    .buttonStyle(BrutalPillStyle(fill: Color.white))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(resultAppeared ? 1 : 0)
                .offset(y: resultAppeared ? 0 : 30)
                .animation(.spring(response: 0.6).delay(1.2), value: resultAppeared)
            }
        }
        .onAppear {
            startResultAnimations()
        }
    }

    private func resetQuiz() {
        withAnimation(.easeOut(duration: 0.25)) {
            isFinished = false
        }
        resultAppeared = false
        scoreAnimated = 0
        starsRevealed = 0
        ringProgress = 0
        glowPulse = false
        currentQuestionIndex = 0
        selectedOptionIndex = nil
        hasAnswered = false
        correctCount = 0
        showFeedback = false
        comboCount = 0
        showCombo = false
        xpEarned = 0
        shuffleAllQuestions()
    }

    private func startResultAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            resultAppeared = true
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        trophyBounce += 1

        let targetScore = correctCount
        let totalQ = max(shuffledQuestions.count, 1)
        withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
            ringProgress = CGFloat(targetScore) / CGFloat(totalQ)
        }

        let steps = targetScore
        for i in 1...max(steps, 1) {
            let delay = 0.5 + Double(i) * (0.8 / Double(max(steps, 1)))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if i <= targetScore {
                    withAnimation(.spring(response: 0.2)) {
                        scoreAnimated = i
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }

        let percentage = Double(targetScore) / Double(totalQ)
        let starCount = percentage >= 0.8 ? 3 : (percentage >= 0.5 ? 2 : 1)
        for i in 0..<starCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + Double(i) * 0.25) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    starsRevealed = i + 1
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
            glowPulse = true
        }
    }

    private var animatedScoreStars: some View {
        HStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { index in
                let isFilled = index < starsRevealed
                ZStack {
                    if isFilled {
                        Image(systemName: "star.fill")
                            .font(.system(size: 38, weight: .black))
                            .foregroundStyle(yellow)
                            .shadow(color: ink, radius: 0, x: 0, y: 3)
                    }
                    Image(systemName: isFilled ? "star.fill" : "star")
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(.clear)
                        .overlay {
                            Image(systemName: isFilled ? "star.fill" : "star")
                                .font(.system(size: 38, weight: .black))
                                .foregroundStyle(isFilled ? yellow : ink.opacity(0.15))
                        }
                }
                .scaleEffect(isFilled ? 1.15 : 0.85)
                .animation(.spring(response: 0.4, dampingFraction: 0.4), value: starsRevealed)
            }
        }
        .opacity(resultAppeared ? 1 : 0)
        .animation(.spring(response: 0.5).delay(1.4), value: resultAppeared)
    }

    // MARK: - Post-quiz XP progression screen

    /// XP-based tiers (mirrors ProgressManager).
    private var subjectTier: (level: Int, lower: Int, upper: Int) {
        let xp = displayedXP
        return ProgressManager.subjectXPTiers.last(where: { xp >= $0.lower }) ?? ProgressManager.subjectXPTiers[0]
    }

    private var subjectTierProgress: Double {
        let t = subjectTier
        if t.level == 5 { return 1.0 }
        let span = max(1, t.upper - t.lower)
        return min(1.0, max(0.0, Double(displayedXP - t.lower) / Double(span)))
    }

    private var barFractionBefore: Double {
        let t = ProgressManager.subjectXPTiers.last(where: { subjectXPBefore >= $0.lower }) ?? ProgressManager.subjectXPTiers[0]
        if t.level == 5 { return 1.0 }
        let span = max(1, t.upper - t.lower)
        return min(1.0, max(0.0, Double(subjectXPBefore - t.lower) / Double(span)))
    }

    private var targetBarProgress: Double {
        let xp = progressManager.xp(for: course.subject)
        let t = ProgressManager.subjectXPTiers.last(where: { xp >= $0.lower }) ?? ProgressManager.subjectXPTiers[0]
        if t.level == 5 { return 1.0 }
        let span = max(1, t.upper - t.lower)
        return min(1.0, max(0.0, Double(xp - t.lower) / Double(span)))
    }

    private var didLevelUp: Bool {
        let before = ProgressManager.subjectXPTiers.last(where: { subjectXPBefore >= $0.lower })?.level ?? 1
        let after = ProgressManager.subjectXPTiers.last(where: { progressManager.xp(for: course.subject) >= $0.lower })?.level ?? 1
        return after > before
    }

    private func startXPProgressionSequence() {
        xpScreenAppeared = false
        xpBarAnimated = false
        xpButtonAppeared = false
        displayedXP = subjectXPBefore
        xpBarFill = XPProgressAnimator.barFraction(for: subjectXPBefore)
        cachedCourseThumb = CourseImageMap.loadImage(for: course.id)
        confettiTrigger += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                xpScreenAppeared = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            xpBarAnimated = true
            xpBarShimmerActive = true
            ShimmerAnimation.runLoop(offset: $xpBarShimmer) { xpBarShimmerActive }

            let endXP = progressManager.xp(for: course.subject)
            XPProgressAnimator.animate(
                from: subjectXPBefore,
                to: endXP,
                setXP: { displayedXP = $0 },
                setLevel: { _ in },
                setBarFill: { fill, animated in
                    if animated {
                        xpBarFill = fill
                    } else {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) { xpBarFill = fill }
                    }
                },
                haptic: {
                    XPProgressAnimator.progressionHaptic(intensity: 0.62)
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.35)
                },
                completion: {
                    xpBarShimmerActive = false
                    displayedXP = endXP
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    if didLevelUp {
                        showLevelUpCelebration = true
                    } else if pendingGlobalRankUp != nil {
                        showGlobalRankUpCelebration = true
                    } else {
                        revealXPContinueButton()
                    }
                }
            )
        }
    }

    private func revealXPContinueButton() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                xpButtonAppeared = true
            }
        }
    }

    private func revealAfterSubjectLevelUp() {
        if pendingGlobalRankUp != nil {
            showGlobalRankUpCelebration = true
        } else {
            revealXPContinueButton()
        }
    }

    private func continueAfterQuizCompletion() {
        if !pendingCardCandidates.isEmpty {
            let card = pendingCardCandidates.removeFirst()
            if let event = progressManager.unlockCard(card) {
                currentCardUnlockEvent = event
                showCardUnlock = true
                return
            }
            continueAfterQuizCompletion()
            return
        }
        if progressManager.pendingGlobalRankUp() != nil {
            showCardRankUp = true
            return
        }
        if !pendingCollectionEvents.isEmpty {
            currentCollectionEvent = pendingCollectionEvents.removeFirst()
            showCollectionProgress = true
            return
        }
        currentCollectionEvent = nil
        if progressManager.shouldShowStreakToday {
            progressManager.markStreakShownToday()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                showStreak = true
            }
        } else {
            onReturnHome()
        }
    }

    private var pendingGlobalRankUp: (previous: GlobalRank, new: GlobalRank, newLevel: Int)? {
        if let globalQuizAwardResult, globalQuizAwardResult.didRankUp {
            return (globalQuizAwardResult.previousRank, globalQuizAwardResult.newRank, globalQuizAwardResult.newLevel)
        }
        return progressManager.pendingGlobalRankUp()
    }

    private var levelBefore: Int {
        ProgressManager.subjectXPTiers.last(where: { subjectXPBefore >= $0.lower })?.level ?? 1
    }

    private var levelAfter: Int {
        ProgressManager.subjectXPTiers.last(where: { progressManager.xp(for: course.subject) >= $0.lower })?.level ?? 1
    }

    private var xpProgressionView: some View {
        ZStack {
            cream.ignoresSafeArea()

            ConfettiView(trigger: confettiTrigger)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 22) {
                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    Text(course.subject.emoji)
                        .font(.system(size: 16))
                    Text(course.subject.shortName.uppercased())
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                        .tracking(0.6)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(ink, in: Capsule())
                .scaleEffect(xpScreenAppeared ? 1 : 0.6)
                .opacity(xpScreenAppeared ? 1 : 0)

                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(ink)
                        .frame(width: 200, height: 200)
                        .offset(y: 8)
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(yellow.opacity(0.35))
                            .frame(width: 200, height: 200)
                            .overlay {
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .strokeBorder(ink, lineWidth: 3.5)
                            }
                        if let thumb = cachedCourseThumb {
                            Color.clear
                                .frame(width: 200, height: 200)
                                .overlay {
                                    Image(uiImage: thumb)
                                        .resizable()
                                        .scaledToFill()
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        } else {
                            SubjectBadgeView(subject: course.subject, emojiSize: 72, cornerRadius: 28)
                                .frame(width: 200, height: 200)
                        }
                    }
                    .scaleEffect(xpScreenAppeared ? 1 : 0.3)
                }

                VStack(spacing: 6) {
                    Text(didLevelUp ? "Niveau supérieur !" : "Progression XP")
                        .font(.system(.title, design: .rounded, weight: .black))
                        .foregroundStyle(ink)
                        .opacity(xpScreenAppeared ? 1 : 0)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(displayedXP)")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundStyle(ink)
                            .monospacedDigit()
                        Text("XP")
                            .font(.system(.title2, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.55))
                    }
                    .opacity(xpScreenAppeared ? 1 : 0)
                }

                VStack(alignment: .leading, spacing: 6) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(ink)
                            .frame(height: 22)
                            .offset(y: 5)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white)
                                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                                    .frame(height: 22)
                                Capsule()
                                    .fill(pink)
                                    .overlay {
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.clear, .white.opacity(0.45), .clear],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .mask {
                                                Rectangle()
                                                    .frame(width: 60, height: 22)
                                                    .offset(x: xpBarShimmer)
                                            }
                                            .allowsHitTesting(false)
                                    }
                                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                                    .frame(width: max(geo.size.width * xpBarFill, 22), height: 22)
                            }
                        }
                        .frame(height: 22)
                    }
                    .padding(.bottom, 5)

                    Text(xpProgressLabel)
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink.opacity(0.6))
                }
                .padding(.horizontal, 24)
                .opacity(xpScreenAppeared ? 1 : 0)

                // Breakdown pills
                VStack(spacing: 10) {
                    breakdownPill(
                        icon: "checkmark.circle.fill",
                        label: "Bonnes réponses",
                        amount: xpEarned - quizCompletionXPBonus,
                        fill: mint
                    )
                    breakdownPill(
                        icon: "trophy.fill",
                        label: "Quiz terminé",
                        amount: quizCompletionXPBonus,
                        fill: yellow
                    )
                }
                .padding(.horizontal, 24)
                .opacity(xpScreenAppeared ? 1 : 0)
                .offset(y: xpScreenAppeared ? 0 : 14)

                Spacer(minLength: 8)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    continueAfterQuizCompletion()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                        Text("Continuer")
                    }
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
                .buttonStyle(BrutalPillStyle(fill: pink))
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .scaleEffect(xpButtonAppeared ? 1 : 0.85)
                .opacity(xpButtonAppeared ? 1 : 0)
            }
        }
    }

    private var xpProgressLabel: String {
        let t = subjectTier
        if t.level == 5 { return "\(displayedXP) XP · niveau max" }
        let toNext = max(0, t.upper - displayedXP)
        return "\(toNext) XP avant niv. \(t.level + 1)"
    }

    private func breakdownPill(icon: String, label: String, amount: Int, fill: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(fill)
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                Image(systemName: icon)
                    .font(.system(.subheadline, weight: .heavy))
                    .foregroundStyle(ink)
            }
            .frame(width: 38, height: 38)

            Text(label)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)

            Spacer(minLength: 4)

            Text("+\(amount) XP")
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(fill, in: Capsule())
                .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
    }
}

/// Neo-brutalist pill button: solid black offset plate behind a colored capsule.
private struct BrutalPillStyle: ButtonStyle {
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

struct ConfettiView: View {
    let trigger: Int
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let elapsed = now - particle.startTime
                    guard elapsed < 3.0 else { continue }
                    let progress = elapsed / 3.0
                    let x = particle.startX + sin(elapsed * particle.wobbleSpeed) * particle.wobbleAmount
                    let y = particle.startY + elapsed * particle.fallSpeed
                    let opacity = 1.0 - progress
                    let rotation = Angle.degrees(elapsed * particle.rotationSpeed)

                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)
                    let rect = CGRect(x: -particle.width / 2, y: -particle.height / 2, width: particle.width, height: particle.height)
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(particle.color)
                    )
                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                    context.opacity = 1
                }
            }
        }
        .onChange(of: trigger) { _, _ in
            spawnParticles()
        }
    }

    private func spawnParticles() {
        let colors: [Color] = [
            Color(red: 1.0, green: 0.553, blue: 0.706),  // pink
            Color(red: 1.0, green: 0.84, blue: 0.35),    // yellow
            Color(red: 0.70, green: 0.95, blue: 0.80),   // mint
            Color(red: 0.66, green: 0.92, blue: 0.96),   // cyan
            Color(red: 0.82, green: 0.78, blue: 1.0),    // lavender
            Color(red: 1.0, green: 0.55, blue: 0.18),    // orange
            .black,
        ]
        let now = Date().timeIntervalSinceReferenceDate
        var newParticles: [ConfettiParticle] = []
        for _ in 0..<60 {
            newParticles.append(ConfettiParticle(
                startX: Double.random(in: 20...380),
                startY: Double.random(in: -40...0),
                fallSpeed: Double.random(in: 120...280),
                wobbleSpeed: Double.random(in: 2...6),
                wobbleAmount: Double.random(in: 15...40),
                rotationSpeed: Double.random(in: 60...200),
                width: Double.random(in: 6...12),
                height: Double.random(in: 8...16),
                color: colors.randomElement()!,
                startTime: now + Double.random(in: 0...0.5)
            ))
        }
        particles = newParticles
    }
}

nonisolated struct ConfettiParticle: Sendable {
    let startX: Double
    let startY: Double
    let fallSpeed: Double
    let wobbleSpeed: Double
    let wobbleAmount: Double
    let rotationSpeed: Double
    let width: Double
    let height: Double
    let color: Color
    let startTime: Double
}


