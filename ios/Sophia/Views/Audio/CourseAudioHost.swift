import SwiftUI

/// Everything the audio mode needs from the app root, kept out of `ContentView`'s body
/// (the type-checker already works hard on it):
///
/// - the premium gate and the paywall hook of `CourseAudioPlayer`;
/// - listening to the end completes the course, like reading it does;
/// - the manifest is refreshed at launch and on every return to the foreground;
/// - the full player sheet, opened by the mini-player.
struct CourseAudioHost: ViewModifier {
    let store: StoreViewModel
    let progressManager: ProgressManager
    @Binding var showPlayer: Bool
    let onShowPaywall: () -> Void

    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showPlayer) {
                AudioPlayerView()
                    .sophiaSheetChrome()
            }
            .onAppear(perform: configure)
            .onChange(of: store.isPremium) { _, isPremium in
                CourseAudioPlayer.shared.isPremium = isPremium
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await CourseAudioCatalog.shared.refresh() }
            }
            .task {
                await CourseAudioCatalog.shared.refresh(force: true)
            }
    }

    private func configure() {
        let player = CourseAudioPlayer.shared
        player.isPremium = store.isPremium
        player.onPaywallNeeded = onShowPaywall
        player.onListenedToEnd = { [progressManager] courseId in
            Self.completeCourse(courseId, progressManager: progressManager)
        }
        player.isCourseCompleted = { [progressManager] courseId in
            progressManager.courseStatus(for: courseId) == .completed
        }
    }

    /// The reader's completion (`CourseView`, last page), minus the celebration screens:
    /// the listener may well be on a bike with the phone in a pocket. Collection XP is
    /// granted here since the reward flow that normally grants it will not run.
    private static func completeCourse(_ courseId: String, progressManager: ProgressManager) {
        guard let course = ContentCatalog.course(withId: courseId) else { return }
        let wasCompleted = progressManager.courseStatus(for: courseId) == .completed
        if !course.lessons.isEmpty {
            progressManager.updateLessonProgress(
                courseId: courseId,
                lessonIndex: course.lessons.count - 1,
                lessonCount: course.lessons.count
            )
        }
        progressManager.completeCourse(courseId: courseId, quizScore: 0)
        TikTokBlockerManager.shared.registerDailyCourseCompleted(courseId: courseId)
        progressManager.addXP(subject: course.subject, amount: CourseView.courseCompletionXP)
        progressManager.awardGlobalXP(
            reason: .courseCompleted(courseId: courseId),
            amount: ProgressManager.globalCourseCompletionXP
        )
        if !wasCompleted {
            for event in progressManager.collectionProgressEvents(forNewlyCompletedCourseId: courseId)
            where event.didCompleteCollection {
                progressManager.awardGlobalXP(
                    reason: .collectionCompleted(id: event.collection.id),
                    amount: progressManager.collectionCompletionXP(for: event.collection)
                )
            }
        }
    }
}

extension View {
    func courseAudioHost(
        store: StoreViewModel,
        progressManager: ProgressManager,
        showPlayer: Binding<Bool>,
        onShowPaywall: @escaping () -> Void
    ) -> some View {
        modifier(CourseAudioHost(
            store: store,
            progressManager: progressManager,
            showPlayer: showPlayer,
            onShowPaywall: onShowPaywall
        ))
    }
}
