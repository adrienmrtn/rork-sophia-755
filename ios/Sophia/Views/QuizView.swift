import SwiftUI

struct QuizView: View {
    let course: Course
    let progressManager: ProgressManager
    let onReturnHome: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var currentQuestionIndex: Int = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var hasAnswered: Bool = false
    @State private var correctCount: Int = 0
    @State private var isFinished: Bool = false
    @State private var showFeedback: Bool = false
    @State private var showCelebration: Bool = false
    @State private var celebrationScale: CGFloat = 0.3
    @State private var confettiTrigger: Int = 0
    @State private var streakBefore: Int = 0
    @State private var completedBefore: Int = 0
    @State private var resultAppeared: Bool = false
    @State private var trophyBounce: Int = 0
    @State private var scoreAnimated: Int = 0
    @State private var starsRevealed: Int = 0
    @State private var ringProgress: CGFloat = 0
    @State private var celebrationAppeared: Bool = false
    @State private var celebrationEmojiBounce: Int = 0
    @State private var streakBarAppeared: Bool = false
    @State private var celebrationButtonAppeared: Bool = false
    @State private var celebrationParticles: [CelebrationParticle] = []
    @State private var glowPulse: Bool = false
    @State private var shuffledQuestions: [ShuffledQuestion] = []
    @State private var questionAppeared: Bool = false
    @State private var comboCount: Int = 0
    @State private var showCombo: Bool = false
    @State private var xpEarned: Int = 0
    @State private var showXPPopup: Bool = false
    @State private var userAnswers: [Int?] = []
    @State private var showCorrections: Bool = false

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
            SophiaTheme.background.ignoresSafeArea()

            if showCelebration {
                celebrationView
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
        .onAppear {
            streakBefore = progressManager.streak
            completedBefore = progressManager.completedCount
            shuffleAllQuestions()
        }
        .sheet(isPresented: $showCorrections) {
            QuizCorrectionsSheet(
                questions: shuffledQuestions,
                answers: userAnswers
            )
            .presentationDragIndicator(.visible)
        }
    }

    private struct QuizCorrectionsSheet: View {
        let questions: [ShuffledQuestion]
        let answers: [Int?]

        var body: some View {
            ZStack {
                SophiaTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Corrections")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Retrouve la bonne réponse pour chaque question")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.top, 8)

                        VStack(spacing: 12) {
                            ForEach(Array(questions.enumerated()), id: \.offset) { i, q in
                                let selected = i < answers.count ? answers[i] : nil
                                let isCorrect = selected == q.correctIndex
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .top, spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill((isCorrect ? SophiaTheme.emerald : SophiaTheme.errorRed).opacity(0.18))
                                                .frame(width: 28, height: 28)
                                            Image(systemName: isCorrect ? "checkmark" : "xmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(isCorrect ? SophiaTheme.emerald : SophiaTheme.errorRed)
                                        }
                                        Text(q.question)
                                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                                            .foregroundStyle(.white)
                                        Spacer(minLength: 0)
                                    }

                                    Text("Ta réponse : " + (selected.map { q.options[$0] } ?? "—"))
                                        .font(.system(.caption, design: .rounded, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.65))

                                    Text("Bonne réponse : " + q.options[q.correctIndex])
                                        .font(.system(.caption, design: .rounded, weight: .bold))
                                        .foregroundStyle(SophiaTheme.emerald)
                                }
                                .padding(14)
                                .background(.white.opacity(0.05), in: .rect(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
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
                correctIndex: newCorrectIndex
            )
        }
        userAnswers = Array(repeating: nil, count: shuffledQuestions.count)
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
            duoProgressBar

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(currentQuestion.question)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .id("question_\(currentQuestionIndex)")
                        .opacity(questionAppeared ? 1 : 0)
                        .offset(y: questionAppeared ? 0 : 15)
                        .padding(.top, 24)

                    VStack(spacing: 12) {
                        ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                            duoOptionButton(index: index, text: option)
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
                .padding(.horizontal, 24)
                .padding(.bottom, showFeedback ? 240 : 40)
            }
            .scrollIndicators(.hidden)

            if showFeedback {
                duoFeedbackBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var duoProgressBar: some View {
        HStack(spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.1))
                        .frame(height: 14)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [SophiaTheme.emerald, SophiaTheme.emerald.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * progressValue, 14), height: 14)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progressValue)
                        .shadow(color: SophiaTheme.emerald.opacity(0.4), radius: 4, y: 0)
                }
            }
            .frame(height: 14)

            if showCombo && comboCount >= 2 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(SophiaTheme.streakOrange)
                    Text("x\(comboCount)")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .foregroundStyle(SophiaTheme.streakOrange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(SophiaTheme.streakOrange.opacity(0.15), in: .capsule)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var quizHeader: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.1), in: Circle())
            }

            Spacer()

            Text("\(currentQuestionIndex + 1)/\(shuffledQuestions.count)")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private func duoOptionButton(index: Int, text: String) -> some View {
        Button {
            guard !hasAnswered else { return }
            selectedOptionIndex = index
            if currentQuestionIndex < userAnswers.count {
                userAnswers[currentQuestionIndex] = index
            }
            hasAnswered = true
            if index == currentQuestion.correctIndex {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                correctCount += 1
                comboCount += 1
                let xp = comboCount >= 3 ? 15 : (comboCount >= 2 ? 12 : 10)
                xpEarned += xp
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
            HStack(spacing: 14) {
                Text("\(Character(UnicodeScalar(65 + index)!))")
                    .font(.system(.callout, design: .rounded, weight: .heavy))
                    .foregroundStyle(optionLetterColor(for: index))
                    .frame(width: 42, height: 42)
                    .background(optionLetterBg(for: index))
                    .clipShape(.rect(cornerRadius: 12))

                Text(text)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                Spacer()

                if hasAnswered && index == currentQuestion.correctIndex {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(SophiaTheme.emerald)
                        .transition(.scale.combined(with: .opacity))
                }

                if hasAnswered && index == selectedOptionIndex && !isCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(SophiaTheme.errorRed)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(duoOptionBg(for: index))
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(duoBorderColor(for: index), lineWidth: hasAnswered && (index == currentQuestion.correctIndex || index == selectedOptionIndex) ? 2.5 : 1.5)
            )
            .shadow(
                color: hasAnswered && index == currentQuestion.correctIndex ? SophiaTheme.emerald.opacity(0.2) : .clear,
                radius: 8, y: 2
            )
            .scaleEffect(hasAnswered && index == selectedOptionIndex ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasAnswered)

    }

    private func optionLetterColor(for index: Int) -> Color {
        guard hasAnswered else { return .white.opacity(0.6) }
        if index == currentQuestion.correctIndex { return .white }
        if index == selectedOptionIndex { return .white }
        return .white.opacity(0.3)
    }

    private func optionLetterBg(for index: Int) -> some ShapeStyle {
        guard hasAnswered else { return AnyShapeStyle(.white.opacity(0.08)) }
        if index == currentQuestion.correctIndex { return AnyShapeStyle(SophiaTheme.emerald) }
        if index == selectedOptionIndex { return AnyShapeStyle(SophiaTheme.errorRed) }
        return AnyShapeStyle(.white.opacity(0.04))
    }

    private func duoBorderColor(for index: Int) -> Color {
        guard hasAnswered else {
            return .white.opacity(0.12)
        }
        if index == currentQuestion.correctIndex { return SophiaTheme.emerald }
        if index == selectedOptionIndex { return SophiaTheme.errorRed }
        return .white.opacity(0.06)
    }

    private func duoOptionBg(for index: Int) -> Color {
        guard hasAnswered else {
            return .white.opacity(0.05)
        }
        if index == currentQuestion.correctIndex { return SophiaTheme.emerald.opacity(0.1) }
        if index == selectedOptionIndex { return SophiaTheme.errorRed.opacity(0.1) }
        return .white.opacity(0.02)
    }

    private func showXPBubble(xp: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showXPPopup = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                showXPPopup = false
            }
        }
    }

    private var xpPopupView: some View {
        VStack {
            Spacer()
                .frame(height: 100)
            Text("+\(comboCount >= 3 ? 15 : (comboCount >= 2 ? 12 : 10)) XP")
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(SophiaTheme.emerald)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(SophiaTheme.emerald.opacity(0.15), in: .capsule)
            Spacer()
        }
    }

    private var duoFeedbackBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isCorrect ? SophiaTheme.emerald.opacity(0.3) : SophiaTheme.errorRed.opacity(0.3))
                .frame(height: 1)

            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(isCorrect ? SophiaTheme.emerald.opacity(0.2) : SophiaTheme.errorRed.opacity(0.2))
                            .frame(width: 52, height: 52)
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(isCorrect ? SophiaTheme.emerald : SophiaTheme.errorRed)
                            .symbolEffect(.bounce, value: showFeedback)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isCorrect ? (comboCount >= 3 ? "Incroyable ! 🔥" : comboCount >= 2 ? "Excellent !" : "Bonne réponse !") : "Pas tout à fait...")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        if !isCorrect {
                            Text("Réponse : \(currentQuestion.options[currentQuestion.correctIndex])")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.white.opacity(0.55))
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    if isCorrect && comboCount >= 2 {
                        VStack(spacing: 2) {
                            Text("🔥")
                                .font(.title3)
                            Text("x\(comboCount)")
                                .font(.system(.caption2, design: .rounded, weight: .heavy))
                                .foregroundStyle(SophiaTheme.streakOrange)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    nextQuestion()
                } label: {
                    Text("Continuer")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            isCorrect ? SophiaTheme.emerald : SophiaTheme.errorRed,
                            in: .rect(cornerRadius: 14)
                        )
                        .shadow(color: (isCorrect ? SophiaTheme.emerald : SophiaTheme.errorRed).opacity(0.3), radius: 8, y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                (isCorrect ? SophiaTheme.emerald.opacity(0.04) : SophiaTheme.errorRed.opacity(0.04))
                    .background(SophiaTheme.cardBackground)
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
            progressManager.completeCourse(courseId: course.id, quizScore: correctCount)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFinished = true
            }
        }
    }


    private var resultView: some View {
        ZStack {
            ResultParticlesView()
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .opacity(resultAppeared ? 1 : 0)

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(SophiaTheme.emerald.opacity(0.06))
                        .frame(width: 200, height: 200)
                        .scaleEffect(resultAppeared ? 1 : 0.3)
                        .opacity(resultAppeared ? 1 : 0)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            AngularGradient(
                                colors: [SophiaTheme.emerald, SophiaTheme.emerald.opacity(0.3), SophiaTheme.emerald],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 170, height: 170)
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .fill(SophiaTheme.emerald.opacity(0.12))
                        .frame(width: 140, height: 140)
                        .scaleEffect(resultAppeared ? 1 : 0.5)

                    VStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(SophiaTheme.streakOrange)
                            .symbolEffect(.bounce, value: trophyBounce)
                            .shadow(color: SophiaTheme.streakOrange.opacity(glowPulse ? 0.6 : 0.2), radius: glowPulse ? 20 : 8)
                    }
                    .scaleEffect(resultAppeared ? 1 : 0)
                }
                .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1), value: resultAppeared)

                VStack(spacing: 10) {
                    Text("Bravo, cours terminé !")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(resultAppeared ? 1 : 0)
                        .offset(y: resultAppeared ? 0 : 15)
                        .animation(.spring(response: 0.5).delay(0.3), value: resultAppeared)

                    HStack(spacing: 4) {
                        Text("\(scoreAnimated)")
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                            .foregroundStyle(SophiaTheme.emerald)
                            .contentTransition(.numericText(countsDown: false))
                        Text("/ \(shuffledQuestions.count)")
                            .font(.system(.title2, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .opacity(resultAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.5), value: resultAppeared)

                    Text("bonnes réponses")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .opacity(resultAppeared ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.6), value: resultAppeared)

                    if xpEarned > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(SophiaTheme.streakOrange)
                            Text("+\(xpEarned) XP")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(SophiaTheme.streakOrange)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(SophiaTheme.streakOrange.opacity(0.12), in: .capsule)
                        .scaleEffect(resultAppeared ? 1 : 0.5)
                        .opacity(resultAppeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.8), value: resultAppeared)
                    }
                }

                animatedScoreStars

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showCelebration = true
                        }
                        celebrationAppeared = false
                        confettiTrigger += 1
                        startCelebrationSequence()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "house.fill")
                            Text("Retour à l'accueil")
                        }
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(SophiaTheme.emerald, in: .rect(cornerRadius: 16))
                        .shadow(color: SophiaTheme.emerald.opacity(0.3), radius: 8, y: 2)
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showCorrections = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet.rectangle")
                            Text("Voir les corrections")
                        }
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(.white.opacity(0.08), in: .rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                        )
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        resetQuiz()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Refaire le quiz")
                        }
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(SophiaTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(SophiaTheme.accent.opacity(0.12), in: .rect(cornerRadius: 16))
                    }
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
        HStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { index in
                let isFilled = index < starsRevealed
                Image(systemName: isFilled ? "star.fill" : "star")
                    .font(.system(size: 36))
                    .foregroundStyle(isFilled ? SophiaTheme.streakOrange : .white.opacity(0.12))
                    .scaleEffect(isFilled ? 1.15 : 0.85)
                    .shadow(color: isFilled ? SophiaTheme.streakOrange.opacity(0.5) : .clear, radius: isFilled ? 10 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.4), value: starsRevealed)
            }
        }
        .opacity(resultAppeared ? 1 : 0)
        .animation(.spring(response: 0.5).delay(1.4), value: resultAppeared)
    }

    private func startCelebrationSequence() {
        celebrationScale = 0.3
        celebrationAppeared = false
        streakBarAppeared = false
        celebrationButtonAppeared = false
        celebrationEmojiBounce = 0
        spawnCelebrationParticles()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.5)) {
                celebrationAppeared = true
                celebrationScale = 1.0
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            celebrationEmojiBounce += 1
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                streakBarAppeared = true
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                celebrationButtonAppeared = true
            }
        }
    }

    private func spawnCelebrationParticles() {
        var p: [CelebrationParticle] = []
        let emojis = ["🎉", "⭐", "✨", "🏆", "🎊", "💫"]
        for i in 0..<12 {
            p.append(CelebrationParticle(
                id: i,
                emoji: emojis[i % emojis.count],
                x: Double.random(in: 30...350),
                y: Double.random(in: 60...700),
                size: Double.random(in: 18...32),
                delay: Double.random(in: 0...1.5),
                duration: Double.random(in: 2.5...4.0),
                drift: Double.random(in: -30...30)
            ))
        }
        celebrationParticles = p
    }

    private var celebrationView: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            ConfettiView(trigger: confettiTrigger)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 28) {
                Spacer()

                let newCompletedCount = progressManager.completedCount
                let isNewStreak = progressManager.streak > streakBefore

                VStack(spacing: 20) {
                    if isNewStreak {
                        VStack(spacing: 8) {
                            Text("🔥")
                                .font(.system(size: 80))
                                .scaleEffect(celebrationScale)
                                .shadow(color: SophiaTheme.streakOrange.opacity(0.6), radius: 20)
                            Text("\(progressManager.streak) jours de suite !")
                                .font(.system(.title2, design: .rounded, weight: .heavy))
                                .foregroundStyle(SophiaTheme.streakOrange)
                                .opacity(celebrationAppeared ? 1 : 0)
                                .offset(y: celebrationAppeared ? 0 : 10)
                        }
                    } else {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(SophiaTheme.streakOrange)
                            .symbolEffect(.bounce, value: celebrationEmojiBounce)
                            .shadow(color: SophiaTheme.streakOrange.opacity(0.5), radius: 16)
                            .scaleEffect(celebrationAppeared ? 1 : 0.3)
                    }

                    VStack(spacing: 10) {
                        Text("Bravo !")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .opacity(celebrationAppeared ? 1 : 0)
                            .scaleEffect(celebrationAppeared ? 1 : 0.7)

                        Text("Tu as terminé ton \(ordinal(newCompletedCount)) cours !")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .opacity(celebrationAppeared ? 1 : 0)
                            .offset(y: celebrationAppeared ? 0 : 10)
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: celebrationAppeared)
                }

                if progressManager.streak >= 2 {
                    HStack(spacing: 8) {
                        Text("🔥")
                            .font(.title2)
                        Text("Streak : \(progressManager.streak) jour\(progressManager.streak > 1 ? "s" : "")")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(SophiaTheme.streakOrange)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(SophiaTheme.streakOrange.opacity(0.15), in: Capsule())
                    .scaleEffect(streakBarAppeared ? 1 : 0.5)
                    .opacity(streakBarAppeared ? 1 : 0)
                }

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onReturnHome()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                        Text("Retour à l'accueil")
                    }
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(SophiaTheme.emerald, in: .rect(cornerRadius: 16))
                    .shadow(color: SophiaTheme.emerald.opacity(0.4), radius: 12, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .scaleEffect(celebrationButtonAppeared ? 1 : 0.8)
                .opacity(celebrationButtonAppeared ? 1 : 0)
            }
        }
    }

    private func ordinal(_ n: Int) -> String {
        if n == 1 { return "1er" }
        return "\(n)e"
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
            SophiaTheme.emerald,
            SophiaTheme.streakOrange,
            SophiaTheme.accent,
            SophiaTheme.errorRed,
            .yellow,
            .cyan,
            .pink,
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

struct CelebrationParticle: Identifiable {
    let id: Int
    let emoji: String
    let x: Double
    let y: Double
    let size: Double
    let delay: Double
    let duration: Double
    let drift: Double
}

struct FloatingEmoji: View {
    let particle: CelebrationParticle
    @State private var appeared: Bool = false
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        Text(particle.emoji)
            .font(.system(size: particle.size))
            .position(x: particle.x + (appeared ? particle.drift : 0), y: particle.y)
            .offset(y: floatOffset)
            .opacity(appeared ? 0.7 : 0)
            .scaleEffect(appeared ? 1 : 0.2)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(particle.delay)) {
                    appeared = true
                }
                withAnimation(
                    .easeInOut(duration: particle.duration)
                    .repeatForever(autoreverses: true)
                    .delay(particle.delay)
                ) {
                    floatOffset = -15
                }
            }
    }
}

struct ResultParticlesView: View {
    @State private var particles: [ResultGlowParticle] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for p in particles {
                    let elapsed = now - p.startTime
                    let looped = elapsed.truncatingRemainder(dividingBy: p.duration)
                    let progress = looped / p.duration
                    let y = p.startY - progress * size.height * 1.2
                    let x = p.startX + sin(looped * p.wobble) * 20
                    let alpha = sin(progress * .pi) * 0.4
                    context.opacity = alpha
                    let rect = CGRect(x: x - p.radius, y: y - p.radius, width: p.radius * 2, height: p.radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(p.color))
                    context.opacity = 1
                }
            }
        }
        .onAppear {
            let colors: [Color] = [SophiaTheme.emerald.opacity(0.6), SophiaTheme.streakOrange.opacity(0.5), .cyan.opacity(0.4), .purple.opacity(0.4)]
            let now = Date().timeIntervalSinceReferenceDate
            var arr: [ResultGlowParticle] = []
            for i in 0..<20 {
                arr.append(ResultGlowParticle(
                    id: i,
                    startX: Double.random(in: 0...400),
                    startY: Double.random(in: 600...900),
                    radius: Double.random(in: 2...5),
                    color: colors.randomElement()!,
                    duration: Double.random(in: 3...6),
                    wobble: Double.random(in: 1...3),
                    startTime: now - Double.random(in: 0...3)
                ))
            }
            particles = arr
        }
    }
}

nonisolated struct ResultGlowParticle: Sendable {
    let id: Int
    let startX: Double
    let startY: Double
    let radius: Double
    let color: Color
    let duration: Double
    let wobble: Double
    let startTime: Double
}
