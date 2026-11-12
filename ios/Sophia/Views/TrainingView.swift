import SwiftUI

/// Spaced-repetition review of quiz questions the learner has already answered once, in a
/// completed course. Deliberately neutral: no XP, no streak, no combo — a pure memorization
/// aid layered on top of the courses/quizzes system (see `ProgressManager`'s training methods
/// and `content/CHARTE_QUIZ.md` for the underlying question types).
///
/// Only questions whose scheduled review date has arrived are shown (`ProgressManager
/// .dueTrainingQuestions`); a session is a fixed snapshot of that due list, shuffled once at
/// the start — answering a question wrong resets it to due-immediately, but it doesn't
/// re-enter the *current* session, only the next one.
struct TrainingView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    var store: StoreViewModel? = nil
    var isPremium: Bool = false
    /// Ouvre le paywall « quizz » (freemium : l'entraînement se remplit via les quiz, premium).
    /// Conservé en fallback si le `store` n'est pas fourni.
    var onShowQuizPaywall: (() -> Void)? = nil

    private struct SessionItem: Identifiable {
        let course: Course
        let question: ShuffledQuestion
        var id: String { question.id }
    }

    @State private var sessionQuestions: [SessionItem] = []
    @State private var isSessionActive = false
    @State private var isSessionComplete = false
    @State private var currentIndex = 0
    @State private var correctCount = 0

    // Per-question answer state — mirrors QuizView's, minus anything XP/combo-related.
    @State private var selectedOptionIndex: Int? = nil
    @State private var chronoSlots: [Int?] = []
    @State private var chronoPool: [Int] = []
    @State private var sliderValue: Double = 0
    @State private var hasAnswered = false
    @State private var wasFullyCorrect = false
    @State private var questionAppeared = false
    @State private var showFeedback = false

    /// Flux « Découvrir/Débloquer » : mini-onboarding entraînement puis paywall.
    @State private var showTrainingFlow = false
    /// Démarre le flux directement sur le paywall (bouton « Débloquer », OB déjà vu).
    @State private var flowStartsAtPaywall = false

    private var currentQuestion: ShuffledQuestion { sessionQuestions[currentIndex].question }
    private var currentCourse: Course { sessionQuestions[currentIndex].course }

    private var isCorrect: Bool {
        selectedOptionIndex == currentQuestion.correctIndex
    }

    var body: some View {
        ZStack {
            // Fond blanc partout : la session se distingue par son en-tête de quiz, plus par un fond teinté.
            DS.canvas.ignoresSafeArea()

            if isSessionComplete {
                summaryView
            } else if isSessionActive, sessionQuestions.indices.contains(currentIndex) {
                sessionView
            } else {
                entryView
            }
        }
        .fullScreenCover(isPresented: $showTrainingFlow) {
            if let store {
                TrainingOnboardingView(
                    store: store,
                    startAtPaywall: flowStartsAtPaywall,
                    onCompletedOnboarding: { TutorialFlags.markSeen(.trainingOnboarding) },
                    onPurchased: { showTrainingFlow = false },
                    onRestored: { showTrainingFlow = false },
                    onClose: { showTrainingFlow = false }
                )
            }
        }
    }

    /// Ouvre le flux « Découvrir » (mini-OB) ou « Débloquer » (paywall direct) selon que
    /// l'utilisateur a déjà parcouru l'onboarding entraînement.
    private func openTrainingFlow() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // Sans `store` (cas improbable), on retombe sur l'ancien paywall via le callback.
        guard store != nil else { onShowQuizPaywall?(); return }
        flowStartsAtPaywall = TutorialFlags.seen(.trainingOnboarding)
        showTrainingFlow = true
    }

    // MARK: - Entry screen

    /// Pastille posée sur l'illustration selon l'état de l'entraînement.
    private enum EntryBadge {
        case none
        case done
        case locked
    }

    private var entryView: some View {
        let due = progressManager.dueTrainingQuestions
        let hasAnyQuestions = !progressManager.progress.trainingQuestionStates.isEmpty
        return VStack(spacing: 0) {
            Text(languageManager.text("training.title"))
                .font(DS.sans(.callout, .heavy))
                .foregroundStyle(DS.ink)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)

            GeometryReader { geo in
                ScrollView {
                    Group {
                        if !due.isEmpty {
                            readyContent(due: due)
                        } else if hasAnyQuestions {
                            allReviewedContent
                        } else {
                            lockedContent
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height)
                }
                .scrollIndicators(.hidden)
            }

            entryButtons(due: due)
        }
    }

    /// Les actions ancrées en bas : « Commencer » pour qui peut réviser, « Découvrir » /
    /// « Débloquer » en freemium (l'entraînement est premium).
    private func entryButtons(due: [(course: Course, question: QuizQuestion)]) -> some View {
        VStack(spacing: 10) {
            // Freemium : pas de bouton « Commencer » — l'entraînement est premium et se
            // débloque via le bouton « Débloquer » (voir `freemiumUnlockButton`).
            if isPremium, !due.isEmpty {
                Button {
                    startSession(due: due)
                } label: {
                    Text(languageManager.text("training.start"))
                }
                .buttonStyle(DSPrimaryButtonStyle())
            }

            if !isPremium {
                freemiumUnlockButton
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // Des questions sont à réviser maintenant.
    private func readyContent(due: [(course: Course, question: QuizQuestion)]) -> some View {
        entryMessage(
            badge: .none,
            title: languageManager.text("training.readyTitle"),
            subtitle: String(format: languageManager.text("training.dueCount"), due.count)
        )
    }

    // Tout est révisé pour l'instant (mais l'utilisateur a déjà des questions).
    private var allReviewedContent: some View {
        entryMessage(
            badge: .done,
            title: languageManager.text("training.emptyTitle"),
            subtitle: languageManager.text("training.emptyMessage")
        )
    }

    // Aucun quiz terminé encore : on présente l'entraînement sans dérouler les explications
    // (elles sont désormais dans le mini-onboarding « Découvrir »).
    private var lockedContent: some View {
        entryMessage(
            badge: .locked,
            title: languageManager.text("training.locked.title"),
            subtitle: languageManager.text("training.locked.tagline")
        )
    }

    private func entryMessage(badge: EntryBadge, title: String, subtitle: String) -> some View {
        VStack(spacing: 14) {
            trainingIllustration(badge: badge)
                .dsPopIn()

            Text(title)
                .font(CourseType.font(24, .semibold, relativeTo: .title2))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
                .dsStagger(1)

            Text(subtitle)
                .font(DS.sans(.callout))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .dsStagger(2)
        }
        .frame(maxWidth: .infinity)
    }

    // CTA freemium : « Découvrir » ouvre le mini-onboarding entraînement (puis le paywall) ;
    // une fois l'onboarding parcouru, le bouton devient « Débloquer » (paywall direct).
    // `openTrainingFlow` porte sa propre vibration : le style du bouton n'en ajoute pas.
    private var freemiumUnlockButton: some View {
        let seenOnboarding = TutorialFlags.seen(.trainingOnboarding)
        return Button(action: openTrainingFlow) {
            HStack(spacing: 8) {
                Image(systemName: seenOnboarding ? "lock.open" : "star")
                    .font(.subheadline.weight(.semibold))
                Text(languageManager.text(seenOnboarding ? "training.unlock" : "training.discover"))
            }
        }
        .buttonStyle(CourseCTAStyle())
    }

    /// L'illustration ronde de l'entraînement, avec une pastille quand tout est révisé
    /// (coche) ou quand il n'y a encore rien à réviser (cadenas).
    private func trainingIllustration(badge: EntryBadge) -> some View {
        Group {
            if let poster = UIImage(named: "training_poster") {
                Image(uiImage: poster)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    DS.accentTint
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 64, weight: .regular))
                        .foregroundStyle(DS.accent)
                }
            }
        }
        .frame(width: 190, height: 190)
        .clipShape(Circle())
        .overlay(alignment: .bottomTrailing) {
            entryBadgeView(badge)
                .offset(x: -6, y: -6)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func entryBadgeView(_ badge: EntryBadge) -> some View {
        switch badge {
        case .none:
            EmptyView()
        case .done:
            DSCheckBadge(size: 38, delay: 0.25)
                .padding(3)
                .background(DS.surface, in: Circle())
        case .locked:
            Image(systemName: "lock.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 38, height: 38)
                .background(DS.accentTint, in: Circle())
                .padding(3)
                .background(DS.surface, in: Circle())
        }
    }

    private func startSession(due: [(course: Course, question: QuizQuestion)]) {
        sessionQuestions = due.shuffled().map { SessionItem(course: $0.course, question: QuizShuffler.shuffle($0.question)) }
        guard !sessionQuestions.isEmpty else { return }
        currentIndex = 0
        correctCount = 0
        isSessionComplete = false
        resetAnswerState()
        questionAppeared = false
        isSessionActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                questionAppeared = true
            }
        }
    }

    private func resetAnswerState() {
        selectedOptionIndex = nil
        if sessionQuestions.indices.contains(currentIndex) {
            let q = sessionQuestions[currentIndex].question
            chronoSlots = Array(repeating: nil, count: q.items.count)
            chronoPool = Array(q.items.indices)
            sliderValue = q.snapToStep((q.sliderMin + q.sliderMax) / 2)
        } else {
            chronoSlots = []
            chronoPool = []
            sliderValue = 0
        }
        hasAnswered = false
        wasFullyCorrect = false
    }

    // MARK: - Answer submission

    private func submitAnswer(_ answer: QuizAnswer) {
        guard !hasAnswered else { return }
        let item = sessionQuestions[currentIndex]
        let fullyCorrect = QuizScoring.isFullyCorrect(for: item.question, answer: answer)

        var props: [String: AnalyticsValue] = [
            "question_id": .string(item.question.id),
            "context": "training",
            "correct": .bool(fullyCorrect),
        ]
        if case .singleChoice(let index) = answer { props["option_index"] = .int(index) }
        AnalyticsService.shared.log(.quizAnswer, courseId: item.course.id, props: props)

        hasAnswered = true
        wasFullyCorrect = fullyCorrect
        if fullyCorrect {
            correctCount += 1
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        progressManager.recordTrainingAnswer(questionId: item.question.id, courseId: item.course.id, correct: fullyCorrect)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showFeedback = true
        }
    }

    private func selectOption(_ index: Int) {
        guard !hasAnswered else { return }
        selectedOptionIndex = index
        submitAnswer(.singleChoice(index))
    }

    private func submitChronoOrder() {
        guard chronoSlots.allSatisfy({ $0 != nil }) else { return }
        submitAnswer(.order(chronoSlots.compactMap { $0 }))
    }

    private func submitSlider() {
        submitAnswer(.value(sliderValue))
    }

    // MARK: - Session screen

    /// « Question 2 sur 8 » : le sur-titre et le libellé VoiceOver de la progression.
    private var questionCountText: String {
        String(
            format: languageManager.text("elevateCourse.quiz.questionOf"),
            currentIndex + 1,
            sessionQuestions.count
        )
    }

    private var sessionView: some View {
        VStack(spacing: 0) {
            CourseQuizTopBar(
                total: sessionQuestions.count,
                filled: currentIndex + 1,
                closeLabel: languageManager.text("common.close"),
                progressLabel: questionCountText,
                onClose: { exitSession() }
            )

            ScrollView {
                VStack(spacing: 26) {
                    questionHeader
                        .opacity(questionAppeared ? 1 : 0)
                        .offset(y: questionAppeared ? 0 : 12)
                        .padding(.top, 26)

                    Group {
                        switch currentQuestion.type {
                        case .mcq, .trueFalse:
                            choiceAnswerBody
                        case .chronological:
                            chronologicalAnswerBody
                        case .numericSlider, .percentageSlider:
                            sliderAnswerBody
                        }
                    }
                    .opacity(questionAppeared ? 1 : 0)
                    .offset(y: questionAppeared ? 0 : 12)
                    .id("training_answer_\(currentIndex)")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)

            if showFeedback {
                feedbackBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func exitSession() {
        withAnimation(.easeOut(duration: 0.2)) {
            isSessionActive = false
            showFeedback = false
        }
        sessionQuestions = []
        currentIndex = 0
    }

    /// Sur-titre « MATIÈRE · QUESTION n SUR N », le cours d'où vient la question, puis l'énoncé.
    private var questionHeader: some View {
        CourseQuizQuestionHeader(
            subject: currentCourse.subject,
            eyebrow: "\(currentCourse.subject.localizedShortName(language: languageManager.current)) · \(questionCountText)",
            question: currentQuestion.question,
            caption: currentCourse.title
        )
        .id("training_question_\(currentIndex)")
    }

    // MARK: - Choice answer (.mcq / .trueFalse) — identical styling to QuizView

    @ViewBuilder
    private var choiceAnswerBody: some View {
        if currentQuestion.type == .trueFalse {
            HStack(spacing: 10) {
                ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                    trueFalseButton(index: index, text: option)
                }
            }
        } else {
            VStack(spacing: 10) {
                ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                    optionRow(index: index, text: option)
                }
            }
        }
    }

    /// État visuel d'une réponse : au repos tant que rien n'est choisi ; ensuite la bonne en
    /// vert, la mauvaise choisie en rouge, les autres estompées.
    private func optionState(for index: Int) -> DSOptionState {
        guard hasAnswered else { return .idle }
        if index == currentQuestion.correctIndex { return .correct }
        if index == selectedOptionIndex { return .wrong }
        return .dimmed
    }

    // Pas de vibration au toucher : le verdict (`submitAnswer`) vibre aussitôt.
    private func optionRow(index: Int, text: String) -> some View {
        let state: DSOptionState = optionState(for: index)
        return Button {
            selectOption(index)
        } label: {
            CourseQuizOptionCard(text: text, state: state)
        }
        .buttonStyle(PressableStyle(haptic: false))
        .dsShake(trigger: state == .wrong ? 1 : 0)
        .dsStagger(index)
    }

    private func trueFalseButton(index: Int, text: String) -> some View {
        let state: DSOptionState = optionState(for: index)
        return Button {
            selectOption(index)
        } label: {
            CourseQuizTrueFalseCard(text: text, isTrue: index == 0, state: state)
        }
        .buttonStyle(PressableStyle(haptic: false))
        .dsShake(trigger: state == .wrong ? 1 : 0)
        .dsStagger(index)
    }

    // MARK: - Chronological ordering answer — identical interaction to QuizView

    private var chronologicalAnswerBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageManager.text("quiz.chronological.instruction"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                ForEach(Array(chronoSlots.indices), id: \.self) { position in
                    chronoSlotView(position: position)
                        .dsStagger(position)
                }
            }

            if !chronoPool.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(languageManager.text("quiz.chronological.remaining").uppercasedInApp())
                        .font(DS.sans(.caption2, .heavy))
                        .foregroundStyle(DS.inkSecondary)
                        .tracking(0.9)

                    VStack(spacing: 8) {
                        ForEach(chronoPool, id: \.self) { slot in
                            chronoPoolChip(slot: slot)
                        }
                    }
                }
            }

            if hasAnswered {
                correctOrderCard
            } else if chronoSlots.allSatisfy({ $0 != nil }) {
                // Pas de vibration au toucher : le verdict vibre aussitôt.
                Button {
                    submitChronoOrder()
                } label: {
                    Text(languageManager.text("quiz.chronological.validate"))
                }
                .buttonStyle(CourseCTAStyle())
                .padding(.top, 4)
                .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
    }

    private var correctOrderCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(languageManager.text("quiz.chronological.correctOrder").uppercasedInApp())
                .font(DS.sans(.caption2, .heavy))
                .foregroundStyle(DS.inkSecondary)
                .tracking(0.9)
            Text(correctChronologicalOrderText)
                .font(DS.sans(.footnote, .medium))
                .foregroundStyle(DS.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .dsCard(padding: 14)
    }

    @ViewBuilder
    private func chronoSlotView(position: Int) -> some View {
        let content = chronoSlotContent(position: position)
        if hasAnswered {
            content
        } else if let slot = chronoSlots[position] {
            content
                .onTapGesture { tapFilledSlot(position) }
                .draggable(String(slot))
                .dropDestination(for: String.self) { items, _ in
                    guard let raw = items.first, let draggedSlot = Int(raw) else { return false }
                    handleChronoDrop(draggedSlot: draggedSlot, targetPosition: position)
                    return true
                }
        } else {
            content
                .dropDestination(for: String.self) { items, _ in
                    guard let raw = items.first, let draggedSlot = Int(raw) else { return false }
                    handleChronoDrop(draggedSlot: draggedSlot, targetPosition: position)
                    return true
                }
        }
    }

    private func chronoSlotContent(position: Int) -> some View {
        let slot: Int? = chronoSlots[position]
        var verdict: CourseQuizSlotVerdict = .pending
        if hasAnswered, let slot {
            var isCorrectSlot = false
            if currentQuestion.originalIndices.indices.contains(slot) {
                isCorrectSlot = currentQuestion.originalIndices[slot] == position
            }
            verdict = isCorrectSlot ? .correct : .wrong
        }
        var text: String? = nil
        if let slot { text = currentQuestion.items[slot] }

        return CourseQuizChronoSlotRow(
            position: position,
            text: text,
            emptyText: languageManager.text("quiz.chronological.emptySlot"),
            verdict: verdict
        )
        .dsShake(trigger: verdict == .wrong ? 1 : 0)
    }

    private func chronoPoolChip(slot: Int) -> some View {
        CourseQuizChronoPoolRow(text: currentQuestion.items[slot])
            .onTapGesture { tapPoolItem(slot) }
            .draggable(String(slot))
    }

    private func tapPoolItem(_ slot: Int) {
        guard !hasAnswered,
              let emptyPosition = chronoSlots.firstIndex(where: { $0 == nil }),
              let poolIndex = chronoPool.firstIndex(of: slot) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            chronoPool.remove(at: poolIndex)
            chronoSlots[emptyPosition] = slot
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func tapFilledSlot(_ position: Int) {
        guard !hasAnswered, chronoSlots.indices.contains(position), let slot = chronoSlots[position] else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            chronoSlots[position] = nil
            chronoPool.append(slot)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func handleChronoDrop(draggedSlot: Int, targetPosition: Int) {
        guard !hasAnswered, chronoSlots.indices.contains(targetPosition) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if let sourcePosition = chronoSlots.firstIndex(of: draggedSlot) {
                chronoSlots.swapAt(sourcePosition, targetPosition)
            } else if let poolIndex = chronoPool.firstIndex(of: draggedSlot) {
                chronoPool.remove(at: poolIndex)
                if let bumped = chronoSlots[targetPosition] {
                    chronoPool.append(bumped)
                }
                chronoSlots[targetPosition] = draggedSlot
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var correctChronologicalOrderText: String {
        let items = currentQuestion.items
        let originalIndices = currentQuestion.originalIndices
        guard !items.isEmpty, items.count == originalIndices.count else { return "" }
        let orderedSlots = items.indices.sorted { originalIndices[$0] < originalIndices[$1] }
        return orderedSlots.map { items[$0] }.joined(separator: " → ")
    }

    // MARK: - Slider answer — identical styling to QuizView

    private var sliderAnswerBody: some View {
        VStack(spacing: 20) {
            Text(sliderValueLabel(sliderValue))
                .font(CourseType.font(44, .heavy, relativeTo: .largeTitle))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                // The step comes from the question: a whole-number slider made an answer
                // like 2.4 impossible to select, and impossible to score.
                Slider(value: $sliderValue, in: sliderBounds, step: currentQuestion.sliderStep)
                    .tint(DS.accent)
                    .disabled(hasAnswered)
                    .sensoryFeedback(.selection, trigger: sliderValue)

                HStack {
                    Text(sliderValueLabel(currentQuestion.sliderMin))
                    Spacer()
                    Text(sliderValueLabel(currentQuestion.sliderMax))
                }
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(DS.inkSecondary)
            }

            if hasAnswered {
                HStack(spacing: 10) {
                    CourseQuizSliderResultPill(
                        label: languageManager.text("quiz.slider.yourGuess"),
                        value: sliderValueLabel(sliderValue),
                        tint: wasFullyCorrect ? CoursePalette.successInk : DS.danger,
                        fill: wasFullyCorrect ? DS.successTint : DS.dangerTint
                    )
                    .dsShake(trigger: wasFullyCorrect ? 0 : 1)

                    CourseQuizSliderResultPill(
                        label: languageManager.text("quiz.slider.correctAnswer"),
                        value: sliderValueLabel(currentQuestion.correctValue),
                        tint: CoursePalette.successInk,
                        fill: DS.successTint
                    )
                }
                .dsPopIn()
            } else {
                // Pas de vibration au toucher : le verdict vibre aussitôt.
                Button {
                    submitSlider()
                } label: {
                    Text(languageManager.text("quiz.slider.validate"))
                }
                .buttonStyle(CourseCTAStyle())
            }
        }
        .dsCard()
        .dsStagger(0)
    }

    private var sliderBounds: ClosedRange<Double> {
        let lo = currentQuestion.sliderMin
        let hi = currentQuestion.sliderMax
        return lo < hi ? lo...hi : 0...100
    }

    private func sliderValueLabel(_ value: Double) -> String {
        // Truncating to an Int showed "23" for an answer of 23.5, telling the learner they
        // were wrong when they were not. The precision follows the question's own step.
        let formatter = NumberFormatter()
        formatter.locale = languageManager.locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = currentQuestion.sliderDecimals
        formatter.maximumFractionDigits = currentQuestion.sliderDecimals
        formatter.usesGroupingSeparator = currentQuestion.sliderDecimals == 0
        let text = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        let unit = currentQuestion.unit
        return unit.isEmpty ? text : "\(text) \(unit)"
    }

    // MARK: - Feedback bar (simplified — no XP/combo)

    /// Le panneau de verdict, comme au quiz du cours, sans XP ni combo. « Continuer » vibre
    /// par son style.
    private var feedbackBar: some View {
        CourseQuizVerdictPanel(
            tone: wasFullyCorrect ? .success : .failure,
            title: wasFullyCorrect ? languageManager.text("quiz.feedback.correct") : languageManager.text("quiz.feedback.wrong"),
            explanation: currentQuestion.explanation,
            continueTitle: currentIndex < sessionQuestions.count - 1 ? languageManager.text("common.continue") : languageManager.text("training.finish"),
            onContinue: { nextQuestion() }
        )
    }

    private func nextQuestion() {
        if currentIndex < sessionQuestions.count - 1 {
            withAnimation(.easeOut(duration: 0.2)) {
                showFeedback = false
                questionAppeared = false
            }
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                currentIndex += 1
                resetAnswerState()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    questionAppeared = true
                }
            }
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                showFeedback = false
                isSessionActive = false
                isSessionComplete = true
            }
        }
    }

    // MARK: - Session summary

    private var summaryView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            VStack(spacing: 14) {
                DSCheckBadge(size: 104, delay: 0.15)
                    .padding(13)
                    .background(DS.successTint, in: Circle())
                    .dsPopIn()

                Text(languageManager.text("training.sessionComplete.title"))
                    .font(CourseType.font(24, .semibold, relativeTo: .title2))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                    .dsStagger(1)

                Text(String(format: languageManager.text("training.sessionComplete.summary"), correctCount, sessionQuestions.count))
                    .font(DS.sans(.callout))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .dsStagger(2)
            }

            Spacer(minLength: 40)

            // Vibre par son style.
            Button {
                finishSession()
            } label: {
                Text(languageManager.text("training.backToTraining"))
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .padding(.bottom, 24)
            .dsStagger(3)
        }
        .padding(.horizontal, 24)
        .onAppear { Haptics.success() }
    }

    private func finishSession() {
        isSessionComplete = false
        sessionQuestions = []
        currentIndex = 0
        correctCount = 0
    }
}
