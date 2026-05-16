import SwiftUI
import UIKit
import RevenueCatUI

struct CourseView: View {
    let course: Course
    let progressManager: ProgressManager
    let isPremium: Bool
    let onDismissToHome: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var paywall: PaywallCoordinator
    @AppStorage("sophia_is_premium") private var isPremiumStored: Bool = false
    @State private var currentIndex: Int = 0
    @State private var showQuiz: Bool = false
    @State private var appeared: Bool = false
    @State private var pageTransition: Bool = false
    @State private var quizButtonPulse: Bool = false
    @State private var quizButtonShimmer: CGFloat = -200
    @State private var showCompletionSummary: Bool = false
    @State private var showStreakSummary: Bool = false
    @ObservedObject private var imageCredits = ImageCreditsStore.shared

    private var isLastLesson: Bool {
        currentIndex == course.lessons.count - 1
    }

    private var premiumActive: Bool {
        isPremium || isPremiumStored
    }

    private var progressValue: Double {
        Double(currentIndex + 1) / Double(course.lessons.count)
    }

    private var completedCountInSubject: Int {
        CourseData.allCourses
            .filter { $0.subject == course.subject && progressManager.courseStatus(for: $0.id) == .completed }
            .count
    }

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                progressBar

                TabView(selection: $currentIndex) {
                    ForEach(Array(course.lessons.enumerated()), id: \.element.id) { index, lesson in
                        lessonContent(lesson: lesson)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4), value: currentIndex)

                bottomButton
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
        .navigationBarBackButtonHidden()
        .fullScreenCover(isPresented: $showQuiz) {
            QuizView(
                course: course,
                progressManager: progressManager,
                isPremium: premiumActive,
                onReturnHome: {
                    showQuiz = false
                    onDismissToHome()
                }
            )
        }
        .fullScreenCover(isPresented: $showCompletionSummary) {
            CourseCompletionSummaryScreen(
                subject: course.subject,
                courseCountInSubject: completedCountInSubject,
                onClose: {
                    showCompletionSummary = false
                    showStreakSummary = true
                },
                onMiniQuiz: {
                    showCompletionSummary = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        if premiumActive {
                            showQuiz = true
                        } else {
                            paywall.presentPrimary(
                                onPurchasedOrRestored: {
                                    DispatchQueue.main.async {
                                        showQuiz = true
                                    }
                                },
                                onDismissWithoutPurchase: {
                                    DispatchQueue.main.async {
                                        onDismissToHome()
                                    }
                                }
                            )
                        }
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showStreakSummary) {
            CourseStreakScreen(
                subject: course.subject,
                streak: max(1, progressManager.streak),
                onNext: {
                    showStreakSummary = false
                    onDismissToHome()
                }
            )
        }
        .onChange(of: currentIndex) { _, _ in
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
        }
        .onAppear {
            progressManager.recordReadingActivity()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Button {
                let g = UIImpactFeedbackGenerator(style: .light)
                g.impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.1), in: Circle())
            }

            Spacer()

            Text("\(currentIndex + 1) / \(course.lessons.count)")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.15))
                    .frame(height: 6)
                Capsule()
                    .fill(SophiaTheme.emerald)
                    .frame(width: geo.size.width * progressValue, height: 6)
                    .animation(.spring(response: 0.4), value: progressValue)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func lessonContent(lesson: LessonPage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(lesson.emoji)
                    .font(.system(size: 48))

                Text(lesson.title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                let blocks = LessonContentParser.parse(lesson.content)
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(blocks) { block in
                        switch block.kind {
                        case .text(let text):
                            Text(markdownAttributedString(text))
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineSpacing(6)
                        case .image(let token):
                            CourseInlineImageView(
                                token: token,
                                creditsStore: imageCredits
                            )
                        case .funFact(let text):
                            FunFactBox(text: text)
                        case .highlight(let text):
                            HighlightBox(text: text)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
    }

    private func markdownAttributedString(_ text: String) -> AttributedString {
        let cleaned = text.replacingOccurrences(of: "\\n", with: "\n")
        if let attributed = try? AttributedString(markdown: cleaned, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }
        return AttributedString(cleaned)
    }

    private var bottomButton: some View {
        Button {
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.impactOccurred()
            if isLastLesson {
                progressManager.updateLessonProgress(courseId: course.id, lessonIndex: currentIndex)
                if premiumActive {
                    if course.hasQuiz {
                        showQuiz = true
                    } else {
                        progressManager.completeCourse(courseId: course.id, quizScore: 0)
                        onDismissToHome()
                    }
                } else {
                    progressManager.completeCourse(courseId: course.id, quizScore: 0)
                    showCompletionSummary = true
                }
            } else {
                withAnimation(.spring(response: 0.4)) {
                    currentIndex += 1
                }
                progressManager.updateLessonProgress(courseId: course.id, lessonIndex: currentIndex)
            }
        } label: {
            HStack(spacing: 8) {
                Text(isLastLesson ? (premiumActive && course.hasQuiz ? "Passer au quiz" : "Continuer") : "Continuer")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Image(systemName: isLastLesson ? (premiumActive && course.hasQuiz ? "questionmark.circle.fill" : "arrow.right") : "arrow.right")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(SophiaTheme.emerald)
                    if isLastLesson && course.hasQuiz && premiumActive {
                        GeometryReader { geo in
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.25), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 80)
                                .offset(x: quizButtonShimmer)
                                .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 16))
                    }
                }
            }
            .clipShape(.rect(cornerRadius: 16))
            .shadow(color: SophiaTheme.emerald.opacity(isLastLesson && course.hasQuiz && premiumActive ? 0.5 : 0.25), radius: isLastLesson && course.hasQuiz && premiumActive ? 16 : 8, y: 2)
            .scaleEffect(isLastLesson && course.hasQuiz && premiumActive && quizButtonPulse ? 1.04 : 1.0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .onChange(of: isLastLesson) { _, newValue in
            if newValue && course.hasQuiz && premiumActive {
                startQuizButtonAnimations()
            }
        }
        .onAppear {
            if isLastLesson && course.hasQuiz && premiumActive {
                startQuizButtonAnimations()
            }
        }
    }

    private func startQuizButtonAnimations() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            quizButtonPulse = true
        }
        shimmerLoop()
    }

    private func shimmerLoop() {
        quizButtonShimmer = -100
        withAnimation(.easeInOut(duration: 1.5)) {
            quizButtonShimmer = UIScreen.main.bounds.width + 100
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if isLastLesson && course.hasQuiz {
                shimmerLoop()
            }
        }
    }
}

private struct CourseCompletionSummaryScreen: View {
    let subject: Subject
    let courseCountInSubject: Int
    let onClose: () -> Void
    let onMiniQuiz: () -> Void
    @State private var appeared: Bool = false

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.black.opacity(0.25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .strokeBorder(subject.color.opacity(0.7), lineWidth: 2)
                            )
                            .frame(width: 240, height: 170)

                        VStack(spacing: 10) {
                            Image(systemName: subject.icon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))

                            Text(subject.shortName)
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.95)

                    VStack(spacing: 10) {
                        Text("Apprentissage terminé !")
                            .font(.system(.title, design: .rounded, weight: .heavy))
                            .foregroundStyle(.white)

                        Text("Tu gagnes en culture")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                            Text("Cours \(subject.shortName) : \(courseCountInSubject) fait(s)")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.06), in: .rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                        )

                        Text("Tu as terminé ton cours gratuit du jour")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                }

                Spacer()

                HStack(spacing: 16) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 54, height: 54)
                            .background(.white.opacity(0.10), in: Circle())
                    }

                    Button(action: onMiniQuiz) {
                        HStack(spacing: 10) {
                            Text("🔒 Mini Quiz")
                                .font(.system(.headline, design: .rounded, weight: .heavy))
                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(SophiaTheme.emerald, in: .rect(cornerRadius: 18))
                        .shadow(color: SophiaTheme.emerald.opacity(0.25), radius: 14, y: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.15)) {
                appeared = true
            }
        }
    }
}

private struct CourseStreakScreen: View {
    let subject: Subject
    let streak: Int
    let onNext: () -> Void
    @State private var appeared: Bool = false

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 14) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 52, weight: .heavy))
                        .foregroundStyle(SophiaTheme.streakOrange)
                        .symbolEffect(.pulse, isActive: appeared)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.85)

                    Text("\(streak)")
                        .font(.system(size: 68, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .opacity(appeared ? 1 : 0)

                    Text("Jour de suite")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .opacity(appeared ? 1 : 0)

                    Text("Tu deviens vraiment cultivé, tu deviens incollable en \(subject.shortName) !")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    WeekStreakRow(streak: streak)
                        .padding(.top, 10)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    Text("En route pour ta série !")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.top, 8)
                        .opacity(appeared ? 1 : 0)
                }

                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onNext)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.15)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                onNext()
            }
        }
    }
}

private struct WeekStreakRow: View {
    let streak: Int

    private var days: [(label: String, isChecked: Bool, isToday: Bool)] {
        let labels = ["lun.", "mar.", "mer.", "jeu.", "ven.", "sam.", "dim."]
        let weekday = Calendar.current.component(.weekday, from: Date())
        let todayIndex = (weekday + 5) % 7
        let start = max(0, todayIndex - max(0, streak - 1))
        return labels.enumerated().map { i, label in
            let checked = i >= start && i <= todayIndex
            return (label, checked, i == todayIndex)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<days.count, id: \.self) { i in
                let day = days[i]
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(day.isChecked ? SophiaTheme.streakOrange.opacity(0.25) : .white.opacity(0.08))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .strokeBorder(day.isToday ? .white.opacity(0.25) : .clear, lineWidth: 1)
                            )
                        if day.isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SophiaTheme.streakOrange)
                        }
                    }
                    Text(day.label)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(day.isToday ? 0.85 : 0.55))
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct FunFactBox: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SophiaTheme.emerald)
                .padding(.top, 2)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(5)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(SophiaTheme.emerald.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct HighlightBox: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.yellow)
                .padding(.top, 2)
            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .lineSpacing(5)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.yellow.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct CourseInlineImageView: View {
    let token: String
    @ObservedObject var creditsStore: ImageCreditsStore
    @State private var onDemandCredit: ImageCredit?

    var body: some View {
        let imageURL = IllustrationFileIndex.shared.url(for: token)
        let resolvedCredit =
            onDemandCredit ??
            creditsStore.credit(for: token) ??
            (imageURL.flatMap { creditsStore.credit(for: $0.lastPathComponent) }) ??
            (imageURL.flatMap { creditsStore.credit(for: $0.deletingPathExtension().lastPathComponent) })

        VStack(alignment: .leading, spacing: 10) {
            if let imageURL, let uiImage = UIImage(contentsOfFile: imageURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    )
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "photo")
                        .foregroundStyle(.white.opacity(0.5))
                    Text(token)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.05), in: .rect(cornerRadius: 14))
            }

            if let credit = resolvedCredit {
                VStack(alignment: .leading, spacing: 4) {
                    Text(credit.originalName)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))

                    Text(credit.displayCopyrightLine)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.22), in: .rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
            }
        }
        .task(id: imageURL?.path ?? token) {
            creditsStore.preloadCreditsIfNeeded(near: imageURL)
            onDemandCredit = await creditsStore.ensureCredit(for: token, near: imageURL)
        }
    }
}
