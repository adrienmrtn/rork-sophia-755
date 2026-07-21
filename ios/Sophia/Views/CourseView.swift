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
    /// Second-chance comparison paywall (both offers, like the end of onboarding), shown after
    /// the user closes the quiz / course-unlock paywall without subscribing.
    @State private var showComparisonPaywall: Bool = false
    @State private var chainComparisonAfterPaywall: Bool = false
    @State private var endPhase: CourseEndPhase = .none
    @State private var previousSubjectCount: Int = 0
    @State private var previousSubjectXP: Int = 0
    @State private var globalCourseAwardResult: GlobalXPAwardResult?
    @State private var pendingCollectionEvents: [CollectionProgressEvent] = []
    @State private var rewardSteps: [PostCompletionRewardStep] = []
    @State private var showRewardFlow: Bool = false
    @State private var sessionTracker: CourseSessionTracker?
    @State private var coachmarkTerm: String? = nil

    /// Fixed XP awarded for finishing a course (reaching the completion screen). Always granted.
    private let courseCompletionXP: Int = 10

    private var isPremium: Bool { store.isPremium }

    /// The one course a free user can fully read today (claimed on open in `ContentView`).
    private var isDailyFreeCourse: Bool {
        progressManager.isDailyFreeCourse(course.id)
    }

    /// Full read + completion access: premium, or this is the free course of the day.
    private var hasFullAccess: Bool {
        isPremium || isDailyFreeCourse
    }

    /// A free user's 2nd+ course of the day: only the intro is readable, the rest is locked.
    private var isCourseLocked: Bool {
        !hasFullAccess
    }

    private var isLastLesson: Bool {
        currentIndex == course.lessons.count - 1
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
                    showFreemiumGate: !isPremium,
                    onClose: {
                        continueAfterCourseCompletion()
                    },
                    onQuizTapped: {
                        if isPremium {
                            showQuiz = true
                        } else {
                            showQuizPaywall = true
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

            if let coachmarkTerm {
                GlossaryCoachmark(
                    term: coachmarkTerm,
                    onDismiss: {
                        TutorialFlags.markSeen(.courseTerms)
                        withAnimation(.easeOut(duration: 0.25)) { self.coachmarkTerm = nil }
                    }
                )
                .transition(.opacity)
                .zIndex(60)
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
            maybeShowTermCoachmark(lessonIndex: currentIndex)
        }
        .onDisappear {
            let reason = sessionTracker?.completed == true ? "completed" : "dismiss"
            sessionTracker?.finish(exitReason: reason)
            sessionTracker = nil
        }
        .onChange(of: currentIndex) { _, newIndex in
            requestAppStoreReviewIfEligible(lessonIndex: newIndex)
            sessionTracker?.recordLessonIndex(newIndex)
            maybeShowTermCoachmark(lessonIndex: newIndex)
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
        .fullScreenCover(isPresented: $showDebloquerPaywall, onDismiss: { presentComparisonIfChained() }) {
            SophiaPaywallView(
                context: .debloquerCours,
                store: store,
                course: course,
                secondsUntilReset: progressManager.secondsUntilDailyReset(),
                onPurchased: { chainComparisonAfterPaywall = false; showDebloquerPaywall = false },
                onRestored: { chainComparisonAfterPaywall = false; showDebloquerPaywall = false },
                onDismissed: { chainComparisonAfterPaywall = true; showDebloquerPaywall = false }
            )
        }
        .fullScreenCover(isPresented: $showQuizPaywall, onDismiss: { presentComparisonIfChained() }) {
            SophiaPaywallView(
                context: .quizz,
                store: store,
                course: course,
                onPurchased: { chainComparisonAfterPaywall = false; showQuizPaywall = false },
                onRestored: { chainComparisonAfterPaywall = false; showQuizPaywall = false },
                onDismissed: { chainComparisonAfterPaywall = true; showQuizPaywall = false }
            )
        }
        .fullScreenCover(isPresented: $showComparisonPaywall) {
            OnboardingV2PaywallComparison(
                store: store,
                onSubscribed: { showComparisonPaywall = false },
                onClose: { showComparisonPaywall = false }
            )
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
                    .font(.jakarta(size: 15, weight: .medium))
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
        if FreemiumGate.isLessonContentLocked(lessonIndex: lessonIndex, isPremium: isPremium, isDailyFreeCourse: isDailyFreeCourse) {
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
                    .font(DS.title(.largeTitle, .semibold))
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
            // Restaure le slide entre les pages : sur un TabView `.page`, seul ce modifieur
            // anime un changement *programmatique* de sélection (bouton « Continuer »).
            // `withAnimation` seul n'anime pas le slide sur iOS 17/18.
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
            if isCourseLocked {
                // Free user's 2nd+ course of the day: only the intro is readable; the CTA
                // opens the course-unlock paywall (framed as "your free course is used up").
                presentDebloquerPaywall()
                return
            }
            if isLastLesson {
                guard FreemiumGate.canCompleteCourse(isPremium: isPremium, isDailyFreeCourse: isDailyFreeCourse) else { return }
                sessionTracker?.recordContinueTap()
                sessionTracker?.markCompleted()
                progressManager.updateLessonProgress(courseId: course.id, lessonIndex: currentIndex)
                let wasCompletedBefore = progressManager.courseStatus(for: course.id) == .completed
                previousSubjectCount = progressManager.completedCount(for: course.subject)
                previousSubjectXP = progressManager.xp(for: course.subject)
                progressManager.completeCourse(courseId: course.id, quizScore: 0)
                progressManager.addXP(subject: course.subject, amount: courseCompletionXP)
                globalCourseAwardResult = progressManager.awardGlobalXP(
                    reason: .courseCompleted(courseId: course.id),
                    amount: ProgressManager.globalCourseCompletionXP
                )
                pendingCollectionEvents = wasCompletedBefore ? [] : progressManager.collectionProgressEvents(forNewlyCompletedCourseId: course.id)
                AnalyticsService.trackCourseCompleted(course: course)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    endPhase = .completed
                }
            } else {
                sessionTracker?.recordContinueTap()
                // Le slide est animé par `.animation(_:value: currentIndex)` sur le TabView.
                currentIndex += 1
                progressManager.updateLessonProgress(courseId: course.id, lessonIndex: currentIndex)
            }
        } label: {
            HStack(spacing: 8) {
                if isCourseLocked {
                    Image(systemName: "lock.open.fill")
                        .font(.subheadline.weight(.semibold))
                    Text(languageManager.text("course.unlock.cta"))
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

    /// After the user closes the quiz / course-unlock paywall without subscribing, present the
    /// comparison paywall (both offers, like the end of onboarding) as a second chance.
    private func presentComparisonIfChained() {
        guard chainComparisonAfterPaywall else { return }
        chainComparisonAfterPaywall = false
        guard !store.isPremium else { return }
        // Small delay so the first cover finishes dismissing before presenting the next.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            showComparisonPaywall = true
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

    /// Coachmark « appuie sur ce mot » affiché quand l'utilisateur voit son premier mot
    /// surligné : déclenché sur la première page (visible) qui contient un terme du glossaire,
    /// et met en avant CE mot précis. Une seule fois par installation.
    private func maybeShowTermCoachmark(lessonIndex: Int) {
        guard !TutorialFlags.seen(.courseTerms) else { return }
        guard coachmarkTerm == nil else { return }
        guard course.lessons.indices.contains(lessonIndex) else { return }
        // Le contenu (et donc les mots surlignés) doit être visible.
        guard !FreemiumGate.isLessonContentLocked(
            lessonIndex: lessonIndex,
            isPremium: isPremium,
            isDailyFreeCourse: isDailyFreeCourse
        ) else { return }
        guard let term = firstGlossaryTerm(lessonIndex: lessonIndex) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard !TutorialFlags.seen(.courseTerms), coachmarkTerm == nil else { return }
            guard endPhase == .none, !showQuiz, !showRewardFlow else { return }
            guard currentIndex == lessonIndex else { return }
            withAnimation(.easeIn(duration: 0.3)) {
                coachmarkTerm = term
            }
        }
    }

    /// Premier terme du glossaire réellement résoluble dans la leçon (v2 `[[…]]`, sinon legacy `<…>`).
    private func firstGlossaryTerm(lessonIndex: Int) -> String? {
        let lesson = course.lessons[lessonIndex]
        if let resolved = CourseContentStore.section(courseId: course.id, sectionId: lesson.id) {
            for block in resolved.section.blocks {
                if let term = firstResolvableTerm(in: Self.blockText(block), open: "[[", close: "]]") {
                    return term
                }
            }
            return nil
        }
        return firstResolvableTerm(in: lesson.content, open: "<", close: ">")
    }

    private static func blockText(_ block: ContentBlockV2) -> String {
        switch block {
        case .heading(let t), .paragraph(let t), .funFact(let t), .takeaway(let t):
            return t
        case .quote(let t, _):
            return t
        case .image, .timeline:
            return ""
        }
    }

    private func firstResolvableTerm(in text: String, open: String, close: String) -> String? {
        var searchStart = text.startIndex
        while let openRange = text.range(of: open, range: searchStart..<text.endIndex) {
            guard let closeRange = text.range(of: close, range: openRange.upperBound..<text.endIndex) else { break }
            let term = String(text[openRange.upperBound..<closeRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !term.isEmpty,
               GlossaryStore.entry(courseId: course.id, courseTitle: course.title, displayTerm: term) != nil {
                return term
            }
            searchStart = closeRange.upperBound
        }
        return nil
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
