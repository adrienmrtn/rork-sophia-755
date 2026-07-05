import SwiftUI
import RevenueCatUI

struct ContentView: View {
    @Environment(LanguageManager.self) private var languageManager
    var onResetOnboarding: (() -> Void)? = nil
    @Binding var deepLinkCourseId: String?

    @State private var progressManager = ProgressManager()
    @State private var storeVM = StoreViewModel()
    @State private var discountManager = DiscountOfferManager()
    @State private var selectedTab: Int = 0
    @State private var selectedCourse: Course? = nil
    @State private var paywallContext: SophiaPaywallContext? = nil

    @State private var showSwipeTutorial: Bool = false
    @State private var pendingCourse: Course? = nil
    @State private var autoSwipeCourseId: String? = nil

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab(languageManager.text("tab.home"), systemImage: "house.fill", value: 0) {
                    HomeView(
                        progressManager: progressManager,
                        discountManager: discountManager,
                        isPremium: storeVM.isPremium,
                        selectedCourse: $selectedCourse,
                        autoSwipeCourseId: $autoSwipeCourseId,
                        onLockedTap: { context in
                            if storeVM.isPremium { return }
                            paywallContext = context
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        },
                        onShowDiscountPaywall: {
                            if storeVM.isPremium { return }
                            paywallContext = .offreDiscount
                        }
                    )
                }

                Tab(languageManager.text("tab.library"), systemImage: "books.vertical.fill", value: 1) {
                    LibraryView(
                        progressManager: progressManager,
                        isPremium: storeVM.isPremium,
                        onShowPaywall: { context in
                            paywallContext = context
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        },
                        selectedCourse: $selectedCourse
                    )
                }

                Tab(languageManager.text("tab.profile"), systemImage: "person.fill", value: 2) {
                    ProfileView(
                        progressManager: progressManager,
                        store: storeVM,
                        selectedCourse: $selectedCourse,
                        onShowPaywall: {
                            paywallContext = .quizz
                        },
                        onResetOnboarding: onResetOnboarding
                    )
                }
            }
            .tint(BrutalPalette.ink)
            .toolbarBackground(BrutalPalette.cream, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .preferredColorScheme(.light)
            .sensoryFeedback(.selection, trigger: selectedTab)
            .onAppear { SophiaTabBarStyle.apply() }
            .onChange(of: selectedCourse) { _, newCourse in
                guard let course = newCourse else { return }
                if let context = FreemiumGate.paywallContext(
                    for: course,
                    isPremium: storeVM.isPremium,
                    hasCompletedCourseToday: progressManager.hasCompletedCourseToday
                ) {
                    selectedCourse = nil
                    pendingCourse = nil
                    paywallContext = context
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    return
                }
                if !storeVM.isPremium {
                    progressManager.incrementFreeCoursesOpened()
                }
                pendingCourse = course
            }
            .fullScreenCover(item: $pendingCourse) { course in
                CourseView(
                    course: course,
                    progressManager: progressManager,
                    isPremium: storeVM.isPremium,
                    onDismissToHome: {
                        let courseId = course.id
                        pendingCourse = nil
                        selectedCourse = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            autoSwipeCourseId = courseId
                        }
                    }
                )
            }
            .onChange(of: pendingCourse) { _, newValue in
                if newValue == nil {
                    selectedCourse = nil
                }
            }

            if showSwipeTutorial, HomeCardPresentation.style == .legacy {
                SwipeTutorialOverlay(onDismiss: {
                    withAnimation(.easeOut(duration: 0.35)) {
                        showSwipeTutorial = false
                    }
                    progressManager.markSwipeTutorialSeen()
                })
                .transition(.opacity)
            }

        }
        .sheet(item: $paywallContext) { context in
            SophiaPaywallView(
                context: context,
                onPurchased: {
                    if context == .offreDiscount { discountManager.markExpired() }
                    paywallContext = nil
                },
                onRestored: { paywallContext = nil },
                onDismissed: { paywallContext = nil }
            )
        }
        .onAppear {
            syncWidgetData()
            guard HomeCardPresentation.style == .legacy else { return }
            if !progressManager.hasSeenSwipeTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showSwipeTutorial = true
                    }
                }
            }
            syncWidgetData()
        }
        .onChange(of: storeVM.isPremium) { _, _ in
            syncWidgetData()
        }
        .onChange(of: progressManager.completedCount) { _, _ in
            syncWidgetData()
        }
        .onChange(of: deepLinkCourseId) { _, courseId in
            openDeepLinkedCourse(courseId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .sophiaWidgetDataShouldSync)) { _ in
            syncWidgetData()
        }
    }

    private func syncWidgetData() {
        let completedIds = Set(
            ContentCatalog.activeCourses
                .filter { progressManager.courseStatus(for: $0.id) == .completed }
                .map(\.id)
        )
        WidgetDataSync.sync(
            isPremium: storeVM.isPremium,
            completedCourseIds: completedIds,
            language: languageManager.current
        )
    }

    private func openDeepLinkedCourse(_ courseId: String?) {
        guard let courseId,
              let course = ContentCatalog.course(withId: courseId) else {
            deepLinkCourseId = nil
            return
        }
        selectedTab = 0
        selectedCourse = course
        deepLinkCourseId = nil
    }
}
