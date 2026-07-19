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
    @State private var pendingCourseSource = "home_tinder"

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
                        onShowDiscountPaywall: {
                            if storeVM.isPremium { return }
                            AnalyticsService.trackDiscountOfferViewed(source: "home_banner")
                            paywallContext = .offreDiscount
                        }
                    )
                }

                Tab(languageManager.text("tab.library"), systemImage: "books.vertical.fill", value: 1) {
                    LibraryView(
                        progressManager: progressManager,
                        selectedCourse: $selectedCourse
                    )
                }

                Tab(languageManager.text("tab.collections"), systemImage: "square.stack.3d.up.fill", value: 2) {
                    CollectionsView(
                        progressManager: progressManager,
                        selectedCourse: $selectedCourse
                    )
                }

                Tab(languageManager.text("tab.training"), systemImage: "arrow.triangle.2.circlepath", value: 3) {
                    TrainingView(progressManager: progressManager)
                }

                Tab(languageManager.text("tab.profile"), systemImage: "person.fill", value: 4) {
                    ProfileView(
                        progressManager: progressManager,
                        store: storeVM,
                        selectedCourse: $selectedCourse,
                        onShowPaywall: {
                            paywallContext = .debloquerCours
                        },
                        onResetOnboarding: onResetOnboarding
                    )
                }
            }
            .tint(DS.accent)
            .toolbarBackground(DS.canvas, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .preferredColorScheme(.light)
            .sensoryFeedback(.selection, trigger: selectedTab)
            .onAppear { SophiaTabBarStyle.apply() }
            .onChange(of: selectedCourse) { _, newCourse in
                guard let course = newCourse else { return }
                if !storeVM.isPremium {
                    progressManager.incrementFreeCoursesOpened()
                }
                pendingCourseSource = courseSourceForCurrentTab()
                pendingCourse = course
            }
            .fullScreenCover(item: $pendingCourse) { course in
                CourseView(
                    course: course,
                    progressManager: progressManager,
                    store: storeVM,
                    openSource: pendingCourseSource,
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

            if discountManager.isGiftPending,
               !storeVM.isPremium,
               selectedTab == 0,
               pendingCourse == nil,
               paywallContext == nil {
                DiscountGiftOverlay(onOpened: {
                    discountManager.consumeGift()
                    discountManager.triggerIfNeeded()
                    AnalyticsService.trackDiscountOfferViewed(source: "gift")
                    paywallContext = .offreDiscount
                })
                .transition(.opacity)
                .zIndex(50)
            }

            if discountManager.isActive,
               !storeVM.isPremium,
               !discountManager.isGiftPending,
               pendingCourse == nil,
               paywallContext == nil {
                DiscountSideTab(discountManager: discountManager) {
                    AnalyticsService.trackDiscountOfferViewed(source: "side_tab")
                    paywallContext = .offreDiscount
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(40)
            }

        }
        .animation(.easeInOut(duration: 0.3), value: discountManager.isGiftPending)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: discountManager.isActive)
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
            AnalyticsService.updateUserContext(
                language: languageManager.current,
                isPremium: storeVM.isPremium,
                onboardingCompleted: true
            )
            // Utilisateurs hors onboarding : ATT une fois le premier écran home visible.
            MetaAdsService.requestTrackingAuthorizationAfterFirstScreen()
            guard HomeCardPresentation.style == .legacy else { return }
            if !progressManager.hasSeenSwipeTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showSwipeTutorial = true
                    }
                }
            }
        }
        .onChange(of: storeVM.isPremium) { _, isPremium in
            AnalyticsService.updateUserContext(
                language: languageManager.current,
                isPremium: isPremium,
                onboardingCompleted: true
            )
        }
        .onChange(of: deepLinkCourseId) { _, courseId in
            openDeepLinkedCourse(courseId)
        }
        .trackAnalyticsLifecycle(isPremium: storeVM.isPremium)
    }

    private func courseSourceForCurrentTab() -> String {
        switch selectedTab {
        case 0:
            return HomeCardPresentation.style == .legacy ? "home_legacy" : "home_tinder"
        case 1:
            return "library"
        case 2:
            return "collections"
        case 3:
            return "training"
        case 4:
            return "profile"
        default:
            return "unknown"
        }
    }

    private func openDeepLinkedCourse(_ courseId: String?) {
        guard let courseId,
              let course = ContentCatalog.course(withId: courseId) else {
            deepLinkCourseId = nil
            return
        }
        selectedTab = 0
        pendingCourseSource = "deep_link"
        AnalyticsService.trackDeepLinkOpened(courseId: courseId)
        selectedCourse = course
        deepLinkCourseId = nil
    }
}
