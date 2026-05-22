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

    private let cream = Color(red: 0.984, green: 0.961, blue: 0.918)
    private let ink = Color.black
    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

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
        HStack(spacing: 14) {
            Button {
                let g = UIImpactFeedbackGenerator(style: .light)
                g.impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ink)
                    .frame(width: 40, height: 40)
                    .background(Color.white, in: Circle())
                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
            }

            progressBar

            Text("\(currentIndex + 1) / \(course.lessons.count)")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(ink)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white)
                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                Capsule()
                    .fill(pink)
                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                    .frame(width: max(20, geo.size.width * progressValue))
                    .animation(.spring(response: 0.4), value: progressValue)
            }
        }
        .frame(height: 18)
    }

    private func lessonContent(lesson: LessonPage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(lesson.title)
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)

                RichContentView(content: lesson.content, accent: course.subject.color)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private var bottomButton: some View {
        Button {
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.impactOccurred()
            if isLastLesson {
                progressManager.updateLessonProgress(courseId: course.id, lessonIndex: currentIndex)
                progressManager.markCourseCompletedToday()
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
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .buttonStyle(DuolingoButtonStyle(fill: pink, shimmer: isLastLesson && course.hasQuiz ? quizButtonShimmer : nil))
        .scaleEffect(isLastLesson && course.hasQuiz && quizButtonPulse ? 1.04 : 1.0)
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

/// Duolingo-style 3D button: solid offset shadow plate behind the colored capsule.
/// Pressing the button drops the front capsule onto the shadow (no blur, no double-text).
private struct DuolingoButtonStyle: ButtonStyle {
    let fill: Color
    let shimmer: CGFloat?
    private let depth: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Capsule().fill(fill)
                    .overlay {
                        if let shimmer {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.35), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .mask {
                                    GeometryReader { geo in
                                        Rectangle()
                                            .frame(width: 80, height: geo.size.height)
                                            .offset(x: shimmer)
                                    }
                                }
                                .allowsHitTesting(false)
                        }
                    }
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

