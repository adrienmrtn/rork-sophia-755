import SwiftUI

struct CourseView: View {
    let course: Course
    let progressManager: ProgressManager
    let isPremium: Bool
    let onDismissToHome: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var showQuiz: Bool = false
    @State private var appeared: Bool = false
    @State private var pageTransition: Bool = false
    @State private var quizButtonPulse: Bool = false
    @State private var quizButtonShimmer: CGFloat = -200
    @State private var showQuizPrePaywall: Bool = false

    private var isLastLesson: Bool {
        currentIndex == course.lessons.count - 1
    }

    private var progressValue: Double {
        Double(currentIndex + 1) / Double(course.lessons.count)
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
                onReturnHome: {
                    showQuiz = false
                    onDismissToHome()
                }
            )
        }
        .onChange(of: currentIndex) { _, _ in
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
        }
        .sheet(isPresented: $showQuizPrePaywall) {
            PrePaywallQuizView(onContinue: {
                showQuizPrePaywall = false
                showQuiz = true
            })
            .presentationDragIndicator(.visible)
        }
        .onAppear {
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

                Text(markdownAttributedString(lesson.content))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(6)
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
                if course.hasQuiz {
                    if isPremium {
                        showQuiz = true
                    } else {
                        showQuizPrePaywall = true
                    }
                } else {
                    progressManager.completeCourse(courseId: course.id, quizScore: 0)
                    onDismissToHome()
                }
            } else {
                withAnimation(.spring(response: 0.4)) {
                    currentIndex += 1
                }
                progressManager.updateLessonProgress(courseId: course.id, lessonIndex: currentIndex)
            }
        } label: {
            HStack(spacing: 8) {
                Text(isLastLesson ? (course.hasQuiz ? "Passer au quiz" : "Terminer le cours") : "Continuer")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Image(systemName: isLastLesson ? (course.hasQuiz ? "questionmark.circle.fill" : "checkmark.circle.fill") : "arrow.right")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(SophiaTheme.emerald)
                    if isLastLesson && course.hasQuiz {
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
            .shadow(color: SophiaTheme.emerald.opacity(isLastLesson && course.hasQuiz ? 0.5 : 0.25), radius: isLastLesson && course.hasQuiz ? 16 : 8, y: 2)
            .scaleEffect(isLastLesson && course.hasQuiz && quizButtonPulse ? 1.04 : 1.0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .onChange(of: isLastLesson) { _, newValue in
            if newValue && course.hasQuiz {
                startQuizButtonAnimations()
            }
        }
        .onAppear {
            if isLastLesson && course.hasQuiz {
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
