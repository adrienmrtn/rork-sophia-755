import StoreKit
import SwiftUI
import RevenueCatUI

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
    @State private var endPhase: CourseEndPhase = .none
    @State private var previousSubjectCount: Int = 0
    @State private var previousSubjectXP: Int = 0
    @State private var globalCourseAwardResult: GlobalXPAwardResult?
    @State private var pendingCollectionEvents: [CollectionProgressEvent] = []
    @State private var currentCollectionEvent: CollectionProgressEvent?
    @State private var collectionCompletionAwardResult: GlobalXPAwardResult?
    @State private var showCollectionProgress: Bool = false
    @State private var showCollectionCompleted: Bool = false
    @State private var showCollectionRankUp: Bool = false

    /// Fixed XP awarded for finishing a course (reaching the completion screen). Always granted.
    private let courseCompletionXP: Int = 10

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

            switch endPhase {
            case .none:
                lessonsBody
            case .completed:
                CourseCompletedView(
                    course: course,
                    progressManager: progressManager,
                    previousSubjectXP: previousSubjectXP,
                    earnedXP: courseCompletionXP,
                    globalAwardResult: globalCourseAwardResult,
                    showFreemiumGate: !isPremium,
                    onClose: {
                        continueAfterCourseCompletion()
                    },
                    onQuizTapped: {
                        if isPremium {
                            showQuiz = true
                        } else {
                            showQuizPrePaywall = true
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .streak:
                StreakCelebrationView(
                    streak: progressManager.streak,
                    subject: course.subject,
                    lastActiveDate: progressManager.progress.lastActiveDate,
                    onReturnHome: { onDismissToHome() }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            progressManager.registerFirstCourseOpenedIfNeeded(course.id)
            requestAppStoreReviewIfEligible(lessonIndex: currentIndex)
        }
        .onChange(of: currentIndex) { _, newIndex in
            requestAppStoreReviewIfEligible(lessonIndex: newIndex)
        }
        .fullScreenCover(isPresented: $showQuiz) {
            QuizView(
                course: course,
                progressManager: progressManager,
                initialCollectionEvents: pendingCollectionEvents,
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
                            continueAfterCourseCompletion()
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
                                continueAfterCourseCompletion()
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
                            continueAfterCourseCompletion()
                        }
                    }
                )
            }
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

                RichContentView(
                    content: lesson.content,
                    accent: course.subject.color,
                    courseTitle: course.title
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    /// Lessons body extracted so we can swap to the end-of-course phase screens.
    private var lessonsBody: some View {
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

    private var bottomButton: some View {
        Button {
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.impactOccurred()
            if isLastLesson {
                progressManager.updateLessonProgress(courseId: course.id, lessonIndex: currentIndex)
                progressManager.markCourseCompletedToday()
                let wasCompletedBefore = progressManager.courseStatus(for: course.id) == .completed
                // Capture XP/count BEFORE awarding so we can animate the bar advancing.
                previousSubjectCount = progressManager.completedCount(for: course.subject)
                previousSubjectXP = progressManager.xp(for: course.subject)
                progressManager.completeCourse(courseId: course.id, quizScore: 0)
                // Always award +10 XP when reaching the end-of-course screen, premium or free.
                progressManager.addXP(subject: course.subject, amount: courseCompletionXP)
                globalCourseAwardResult = progressManager.awardGlobalXP(
                    reason: .courseCompleted(courseId: course.id),
                    amount: ProgressManager.globalCourseCompletionXP
                )
                pendingCollectionEvents = wasCompletedBefore ? [] : progressManager.collectionProgressEvents(forNewlyCompletedCourseId: course.id)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    endPhase = .completed
                }
            } else {
                withAnimation(.spring(response: 0.4)) {
                    currentIndex += 1
                }
                progressManager.updateLessonProgress(courseId: course.id, lessonIndex: currentIndex)
            }
        } label: {
            HStack(spacing: 8) {
                Text(isLastLesson ? "Terminer le cours" : "Continuer")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Image(systemName: isLastLesson ? "checkmark.circle.fill" : "arrow.right")
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
        ShimmerAnimation.runLoop(offset: $quizButtonShimmer) {
            isLastLesson && course.hasQuiz
        }
    }

    /// Third lesson (index 2) of the first course ever opened — once per install.
    private func requestAppStoreReviewIfEligible(lessonIndex: Int) {
        guard lessonIndex == 2 else { return }
        guard progressManager.firstCourseOpenedId == course.id else { return }
        guard !progressManager.hasRequestedAppStoreReview else { return }
        progressManager.markAppStoreReviewRequested()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func continueAfterCourseCompletion() {
        if !pendingCollectionEvents.isEmpty {
            currentCollectionEvent = pendingCollectionEvents.removeFirst()
            showCollectionProgress = true
            return
        }
        currentCollectionEvent = nil
        if progressManager.shouldShowStreakToday {
            progressManager.markStreakShownToday()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                endPhase = .streak
            }
        } else {
            onDismissToHome()
        }
    }
}
