import StoreKit
import SwiftUI
import RevenueCatUI

struct CourseView: View {
    @Environment(LanguageManager.self) private var languageManager

    let course: Course
    let progressManager: ProgressManager
    @Bindable var store: StoreViewModel
    var openSource: String = "unknown"
    let onDismissToHome: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var showQuiz: Bool = false
    @State private var appeared: Bool = false
    @State private var quizButtonPulse: Bool = false
    @State private var quizButtonShimmer: CGFloat = -200
    @State private var showDebloquerPaywall: Bool = false
    @State private var endPhase: CourseEndPhase = .none
    @State private var previousSubjectCount: Int = 0
    @State private var previousSubjectXP: Int = 0
    @State private var globalCourseAwardResult: GlobalXPAwardResult?
    @State private var pendingCardCandidates: [CollectibleCard] = []
    @State private var pendingCollectionEvents: [CollectionProgressEvent] = []
    @State private var rewardSteps: [PostCompletionRewardStep] = []
    @State private var showRewardFlow: Bool = false
    @State private var sessionTracker: CourseSessionTracker?

    /// Fixed XP awarded for finishing a course (reaching the completion screen). Always granted.
    private let courseCompletionXP: Int = 10

    private var isPremium: Bool { store.isPremium }

    private var isLastLesson: Bool {
        currentIndex == course.lessons.count - 1
    }

    private var showsUnlockInsteadOfComplete: Bool {
        isLastLesson && !isPremium
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
                    showFreemiumGate: false,
                    onClose: {
                        continueAfterCourseCompletion()
                    },
                    onQuizTapped: {
                        showQuiz = true
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

            if showRewardFlow {
                PostCompletionRewardFlowView(
                    steps: rewardSteps,
                    progressManager: progressManager,
                    onFinished: {
                        showRewardFlow = false
                        onDismissToHome()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
                .zIndex(50)
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            progressManager.registerFirstCourseOpenedIfNeeded(course.id)
            requestAppStoreReviewIfEligible(lessonIndex: currentIndex)
            sessionTracker = CourseSessionTracker(course: course)
            sessionTracker?.recordLessonIndex(currentIndex)
            AnalyticsService.trackCourseOpened(
                courseId: course.id,
                subject: course.subject,
                source: openSource,
                isFreeUser: !isPremium
            )
        }
        .onDisappear {
            let reason = sessionTracker?.completed == true ? "completed" : "dismiss"
            sessionTracker?.finish(exitReason: reason)
            sessionTracker = nil
        }
        .onChange(of: currentIndex) { _, newIndex in
            requestAppStoreReviewIfEligible(lessonIndex: newIndex)
            sessionTracker?.recordLessonIndex(newIndex)
        }
        .fullScreenCover(isPresented: $showQuiz) {
            QuizView(
                course: course,
                progressManager: progressManager,
                initialCollectionEvents: pendingCollectionEvents,
                initialCardCandidates: pendingCardCandidates,
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
        .sheet(isPresented: $showDebloquerPaywall) {
            SophiaPaywallView(
                context: .debloquerCours,
                onPurchased: { showDebloquerPaywall = false },
                onRestored: { showDebloquerPaywall = false },
                onDismissed: { showDebloquerPaywall = false }
            )
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

    @ViewBuilder
    private func lessonContent(lesson: LessonPage, lessonIndex: Int) -> some View {
        if FreemiumGate.isLessonContentLocked(lessonIndex: lessonIndex, isPremium: isPremium) {
            lockedLessonView(lesson: lesson)
        } else {
            unlockedLessonView(lesson: lesson, lessonIndex: lessonIndex)
        }
    }

    private func unlockedLessonView(lesson: LessonPage, lessonIndex: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(lesson.title)
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)

                RichContentView(
                    content: lesson.content,
                    accent: course.subject.color,
                    courseId: course.id,
                    courseTitle: course.title
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, offset in
            guard lessonIndex == 0, offset > 120 else { return }
            sessionTracker?.scrolledOnFirstLesson = true
        }
    }

    /// Locked pages stay vertically scrollable: title stays crisp, the body
    /// quickly blurs, and the unlock card remains centered on the visible screen.
    private func lockedLessonView(lesson: LessonPage) -> some View {
        GeometryReader { geo in
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(lesson.title)
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink)
                            .fixedSize(horizontal: false, vertical: true)

                        ProgressiveBlurView(blurRadius: 18, fullBlurLocation: 0.08) {
                            RichContentView(
                                content: lesson.content,
                                accent: course.subject.color,
                                courseId: course.id,
                                courseTitle: course.title
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, max(geo.size.height * 0.34, 180))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.hidden)

                CourseLessonLockOverlay {
                    presentDebloquerPaywall()
                }
            }
        }
    }

    private var lessonsBody: some View {
        VStack(spacing: 0) {
            headerBar

            TabView(selection: $currentIndex) {
                ForEach(Array(course.lessons.enumerated()), id: \.element.id) { index, lesson in
                    lessonContent(lesson: lesson, lessonIndex: index)
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
            if showsUnlockInsteadOfComplete {
                presentDebloquerPaywall()
                return
            }
            if isLastLesson {
                guard FreemiumGate.canCompleteCourse(isPremium: isPremium) else { return }
                sessionTracker?.recordContinueTap()
                sessionTracker?.markCompleted()
                progressManager.updateLessonProgress(courseId: course.id, lessonIndex: currentIndex)
                let wasCompletedBefore = progressManager.courseStatus(for: course.id) == .completed
                let cardCandidates = progressManager.cardUnlockCandidates(forCompletingCourseId: course.id)
                previousSubjectCount = progressManager.completedCount(for: course.subject)
                previousSubjectXP = progressManager.xp(for: course.subject)
                progressManager.completeCourse(courseId: course.id, quizScore: 0)
                progressManager.addXP(subject: course.subject, amount: courseCompletionXP)
                globalCourseAwardResult = progressManager.awardGlobalXP(
                    reason: .courseCompleted(courseId: course.id),
                    amount: ProgressManager.globalCourseCompletionXP
                )
                pendingCardCandidates = wasCompletedBefore ? [] : cardCandidates
                pendingCollectionEvents = wasCompletedBefore ? [] : progressManager.collectionProgressEvents(forNewlyCompletedCourseId: course.id)
                AnalyticsService.trackCourseCompleted(course: course)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    endPhase = .completed
                }
            } else {
                sessionTracker?.recordContinueTap()
                withAnimation(.spring(response: 0.4)) {
                    currentIndex += 1
                }
                progressManager.updateLessonProgress(courseId: course.id, lessonIndex: currentIndex)
            }
        } label: {
            HStack(spacing: 8) {
                if showsUnlockInsteadOfComplete {
                    Image(systemName: "sparkles")
                        .font(.subheadline.weight(.semibold))
                    Text(languageManager.text("course.quiz.access"))
                        .font(.system(.headline, design: .rounded, weight: .bold))
                } else {
                    Text(isLastLesson ? "Terminer le cours" : "Continuer")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Image(systemName: isLastLesson ? "checkmark.circle.fill" : "arrow.right")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .buttonStyle(
            DuolingoButtonStyle(
                fill: showsUnlockInsteadOfComplete ? Color(red: 0.18, green: 0.72, blue: 0.55) : pink,
                shimmer: shouldShimmerBottomButton ? quizButtonShimmer : nil
            )
        )
        .scaleEffect(shouldPulseBottomButton && quizButtonPulse ? 1.04 : 1.0)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .onChange(of: isLastLesson) { _, newValue in
            if newValue && shouldPulseBottomButton {
                startQuizButtonAnimations()
            }
        }
        .onAppear {
            if shouldPulseBottomButton {
                startQuizButtonAnimations()
            }
        }
    }

    private var shouldShimmerBottomButton: Bool {
        showsUnlockInsteadOfComplete || (isLastLesson && course.hasQuiz && isPremium)
    }

    private var shouldPulseBottomButton: Bool {
        shouldShimmerBottomButton
    }

    private func presentDebloquerPaywall() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showDebloquerPaywall = true
    }

    private func startQuizButtonAnimations() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            quizButtonPulse = true
        }
        shimmerLoop()
    }

    private func shimmerLoop() {
        ShimmerAnimation.runLoop(offset: $quizButtonShimmer) {
            isLastLesson && course.hasQuiz && isPremium
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
        rewardSteps = buildRewardSteps()
        if rewardSteps.isEmpty {
            onDismissToHome()
        } else {
            showRewardFlow = true
        }
    }

    private func buildRewardSteps() -> [PostCompletionRewardStep] {
        var steps: [PostCompletionRewardStep] = []

        while !pendingCardCandidates.isEmpty {
            let card = pendingCardCandidates.removeFirst()
            if let event = progressManager.unlockCard(card) {
                steps.append(.card(event))
            }
        }
        if progressManager.pendingGlobalRankUp() != nil {
            if let pending = progressManager.pendingGlobalRankUp() {
                steps.append(.globalRankUp(previous: pending.previous, new: pending.new, newLevel: pending.newLevel))
            }
        }

        while !pendingCollectionEvents.isEmpty {
            let event = pendingCollectionEvents.removeFirst()
            steps.append(.collectionProgress(event))
            if event.didCompleteCollection {
                let award = progressManager.awardGlobalXP(
                    reason: .collectionCompleted(id: event.collection.id),
                    amount: progressManager.collectionCompletionXP(for: event.collection)
                )
                steps.append(.collectionCompleted(event, awardedXP: award.awardedXP))
                if award.didRankUp {
                    steps.append(.globalRankUp(previous: award.previousRank, new: award.newRank, newLevel: award.newLevel))
                }
            }
        }

        if progressManager.shouldShowStreakToday {
            progressManager.markStreakShownToday()
            steps.append(.streak(streak: progressManager.streak, subject: course.subject, lastActiveDate: progressManager.progress.lastActiveDate))
        }
        return steps
    }
}
