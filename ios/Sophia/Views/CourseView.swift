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
    @State private var showDebloquerPaywall: Bool = false
    @State private var showQuizPaywall: Bool = false
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

    private let cream = DS.canvas

    /// Anchor id used to snap each lesson page back to the top on arrival.
    private static let lessonTopID = "lessonTopAnchor"

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
        .sheet(isPresented: $showQuizPaywall) {
            SophiaPaywallView(
                context: .quizz,
                onPurchased: { showQuizPaywall = false },
                onRestored: { showQuizPaywall = false },
                onDismissed: { showQuizPaywall = false }
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
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }

            progressBar

            Text("\(currentIndex + 1) / \(course.lessons.count)")
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.inkSecondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DS.hairline)
                Capsule()
                    .fill(DS.accent)
                    .frame(width: max(8, geo.size.width * progressValue))
                    .animation(.spring(response: 0.4), value: progressValue)
            }
        }
        .frame(height: 6)
    }

    @ViewBuilder
    private func lessonContent(lesson: LessonPage, lessonIndex: Int) -> some View {
        if FreemiumGate.isLessonContentLocked(lessonIndex: lessonIndex, isPremium: isPremium) {
            lockedLessonView(lesson: lesson, lessonIndex: lessonIndex)
        } else {
            unlockedLessonView(lesson: lesson, lessonIndex: lessonIndex)
        }
    }

    /// Renders a lesson with the structured v2 block engine when content exists for it,
    /// otherwise falls back to the legacy `RichContentView` string renderer.
    @ViewBuilder
    private func lessonBody(lesson: LessonPage) -> some View {
        if let resolved = CourseContentStore.section(courseId: course.id, sectionId: lesson.id) {
            BlockContentView(
                content: resolved.content,
                section: resolved.section,
                isFirst: resolved.isFirst,
                accent: DS.accentSoft,
                courseId: course.id,
                courseTitle: course.title
            )
        } else {
            VStack(alignment: .leading, spacing: 24) {
                Text(lesson.title)
                    .font(DS.serif(.largeTitle, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)

                RichContentView(
                    content: lesson.content,
                    accent: DS.accentSoft,
                    courseId: course.id,
                    courseTitle: course.title
                )
            }
        }
    }

    private func unlockedLessonView(lesson: LessonPage, lessonIndex: Int) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                Color.clear.frame(height: 0).id(Self.lessonTopID)
                lessonBody(lesson: lesson)
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
            .onChange(of: currentIndex) { oldIndex, newIndex in
                // Only reset to the top when moving forward (Continue / swipe next).
                // Going back keeps the previous reading position.
                guard newIndex == lessonIndex, newIndex > oldIndex else { return }
                proxy.scrollTo(Self.lessonTopID, anchor: .top)
            }
        }
    }

    /// Locked pages stay vertically scrollable: title stays crisp, the body
    /// quickly blurs, and the unlock card remains centered on the visible screen.
    private func lockedLessonView(lesson: LessonPage, lessonIndex: Int) -> some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ZStack {
                    ScrollView {
                        Color.clear.frame(height: 0).id(Self.lessonTopID)
                        lessonBody(lesson: lesson)
                            .compositingGroup()
                            .blur(radius: 5)
                            .allowsHitTesting(false)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, max(geo.size.height * 0.34, 180))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: currentIndex) { oldIndex, newIndex in
                        guard newIndex == lessonIndex, newIndex > oldIndex else { return }
                        proxy.scrollTo(Self.lessonTopID, anchor: .top)
                    }

                    CourseLessonLockOverlay {
                        presentDebloquerPaywall()
                    }
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
                showQuizPaywall = true
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
                    Text(languageManager.text("course.quiz.access"))
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                } else {
                    Text(isLastLesson ? "Terminer le cours" : "Continuer")
                    Image(systemName: isLastLesson ? "checkmark" : "arrow.right")
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .buttonStyle(DSPrimaryButtonStyle())
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private func presentDebloquerPaywall() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showDebloquerPaywall = true
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
