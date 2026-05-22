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
                    Image(systemName: course.subject.icon)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
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
                let xp = comboCount >= 3 ? 15 : (comboCount >= 2 ? 12 : 10)
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

                    Spacer(minLength: 4)

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
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
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
        if index == selectedOptionIndex { return coral }
        return Color.white.opacity(0.6)
    }

    private func optionLetterFg(for index: Int) -> Color {
        guard hasAnswered else { return ink }
        if index == currentQuestion.correctIndex { return ink }
        if index == selectedOptionIndex { return ink }
        return ink.opacity(0.4)
    }

    private func optionLetterBg(for index: Int) -> some ShapeStyle {
        guard hasAnswered else { return AnyShapeStyle(yellow) }
        if index == currentQuestion.correctIndex { return AnyShapeStyle(Color.white) }
        if index == selectedOptionIndex { return AnyShapeStyle(Color.white) }
        return AnyShapeStyle(Color.white.opacity(0.5))
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
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(ink)
                Text("+\(comboCount >= 3 ? 15 : (comboCount >= 2 ? 12 : 10)) XP")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(yellow, in: Capsule())
            .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
            .shadow(color: ink.opacity(0.9), radius: 0, x: 0, y: 4)
            Spacer()
        }
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
                        if !isCorrect {
                            Text("Réponse : \(currentQuestion.options[currentQuestion.correctIndex])")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(ink.opacity(0.7))
                                .lineLimit(2)
                        } else if comboCount >= 2 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption.weight(.heavy))
                                Text("Combo x\(comboCount)")
                                    .font(.system(.caption, design: .rounded, weight: .heavy))
                            }
                            .foregroundStyle(ink)
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
            progressManager.completeCourse(courseId: course.id, quizScore: correctCount)
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
            cream.ignoresSafeArea()

            ConfettiView(trigger: confettiTrigger)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 24) {
                Spacer()

                let newCompletedCount = progressManager.completedCount
                let isNewStreak = progressManager.streak > streakBefore

                VStack(spacing: 20) {
                    if isNewStreak {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(ink)
                                    .frame(width: 140, height: 140)
                                    .offset(y: 7)
                                Circle()
                                    .fill(orange)
                                    .frame(width: 140, height: 140)
                                    .overlay { Circle().strokeBorder(ink, lineWidth: 3.5) }
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 70, weight: .black))
                                    .foregroundStyle(.white)
                            }
                            .scaleEffect(celebrationScale)

                            Text("\(progressManager.streak) jours de suite !")
                                .font(.system(.title2, design: .rounded, weight: .black))
                                .foregroundStyle(ink)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(yellow, in: Capsule())
                                .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                                .opacity(celebrationAppeared ? 1 : 0)
                                .offset(y: celebrationAppeared ? 0 : 10)
                        }
                    } else {
                        ZStack {
                            Circle()
                                .fill(ink)
                                .frame(width: 140, height: 140)
                                .offset(y: 7)
                            Circle()
                                .fill(pink)
                                .frame(width: 140, height: 140)
                                .overlay { Circle().strokeBorder(ink, lineWidth: 3.5) }
                            Image(systemName: "party.popper.fill")
                                .font(.system(size: 64, weight: .black))
                                .foregroundStyle(ink)
                                .symbolEffect(.bounce, value: celebrationEmojiBounce)
                        }
                        .scaleEffect(celebrationAppeared ? 1 : 0.3)
                    }

                    VStack(spacing: 10) {
                        Text("Bravo !")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(ink)
                            .opacity(celebrationAppeared ? 1 : 0)
                            .scaleEffect(celebrationAppeared ? 1 : 0.7)

                        Text("Tu as terminé ton \(ordinal(newCompletedCount)) cours !")
                            .font(.system(.title3, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .opacity(celebrationAppeared ? 1 : 0)
                            .offset(y: celebrationAppeared ? 0 : 10)
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: celebrationAppeared)
                }

                if progressManager.streak >= 2 {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(ink)
                        Text("Streak : \(progressManager.streak) jour\(progressManager.streak > 1 ? "s" : "")")
                            .font(.system(.headline, design: .rounded, weight: .black))
                            .foregroundStyle(ink)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(orange, in: Capsule())
                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
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
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
                .buttonStyle(BrutalPillStyle(fill: pink))
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
