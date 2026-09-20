import SwiftUI
import RevenueCatUI

struct ContentView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AppearanceManager.self) private var appearance
    @Environment(AuthService.self) private var auth
    var onResetOnboarding: (() -> Void)? = nil
    let router: DeepLinkRouter

    @State private var progressManager = ProgressManager()
    @State private var syncService = ProgressSyncService.shared
    @State private var storeVM = StoreViewModel()
    @State private var discountManager = DiscountOfferManager()
    @State private var selectedTab: Int = 0
    @State private var selectedCourse: Course? = nil
    @State private var paywallContext: SophiaPaywallContext? = nil

    @State private var showSwipeTutorial: Bool = false
    @State private var pendingCourse: Course? = nil
    @State private var autoSwipeCourseId: String? = nil
    @State private var pendingCourseSource = "home_tinder"
    @State private var showTrialEndingBanner: Bool = false
    @State private var showMyCourses: Bool = false
    /// Set by an entry point that knows where the course came from (a link, the history
    /// screen) and consumed on the next open.
    @State private var explicitCourseSource: String? = nil

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
                            discountManager.markShownToday()
                            paywallContext = .offreDiscount
                        },
                        onOpenMyCourses: { showMyCourses = true }
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
                    TrainingView(
                        progressManager: progressManager,
                        store: storeVM,
                        isPremium: storeVM.isPremium,
                        onShowQuizPaywall: {
                            if storeVM.isPremium { return }
                            paywallContext = .entrainement
                        }
                    )
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
            .sensoryFeedback(.selection, trigger: selectedTab)
            .onAppear { SophiaTabBarStyle.apply() }
            .onChange(of: appearance.preference) { _, _ in
                SophiaTabBarStyle.apply()
            }
            .onChange(of: selectedCourse) { _, newCourse in
                guard let course = newCourse else { return }
                if !storeVM.isPremium {
                    progressManager.incrementFreeCoursesOpened()
                    // "Consumed on open": the first course a free user opens today becomes
                    // their free course of the day (fully readable + revisitable). Every other
                    // course opened today is intro-only + locked.
                    progressManager.claimDailyFreeCourseIfNeeded(course.id)
                }
                // An entry point that names itself keeps its name. This used to overwrite
                // every source with the current tab, so a course opened from a link was
                // reported as opened from home.
                if let explicit = explicitCourseSource {
                    pendingCourseSource = explicit
                    explicitCourseSource = nil
                } else {
                    pendingCourseSource = courseSourceForCurrentTab()
                }
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
                .sophiaColorScheme()
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
                    discountManager.markShownToday()
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
                    discountManager.markShownToday()
                    paywallContext = .offreDiscount
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(40)
            }

            if showTrialEndingBanner {
                VStack(spacing: 0) {
                    TrialEndingMiniBanner()
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer(minLength: 0)
                }
                .safeAreaPadding(.top)
                .allowsHitTesting(false)
                .zIndex(60)
            }

        }
        .animation(.easeInOut(duration: 0.3), value: discountManager.isGiftPending)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: discountManager.isActive)
        .animation(.easeInOut(duration: 0.25), value: showTrialEndingBanner)
        .fullScreenCover(isPresented: $showMyCourses) {
            MyCoursesView(
                progressManager: progressManager,
                onOpenCourse: { course in
                    showMyCourses = false
                    explicitCourseSource = "my_courses"
                    // The sheet has to be gone before the reader is presented, or the two
                    // presentations race and neither appears.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        selectedCourse = course
                    }
                },
                onDiscover: { selectedTab = 0 }
            )
        }
        .fullScreenCover(item: $paywallContext) { context in
            SophiaPaywallView(
                context: context,
                store: storeVM,
                discountManager: discountManager,
                secondsUntilReset: context == .debloquerCours ? progressManager.secondsUntilDailyReset() : nil,
                retentionSummary: context == .retention
                    ? RetentionSummary.current(store: storeVM, progressManager: progressManager)
                    : nil,
                onContinueToCancel: nil,
                onPurchased: {
                    if context == .offreDiscount { discountManager.markExpired() }
                    paywallContext = nil
                },
                onRestored: { paywallContext = nil },
                onDismissed: { paywallContext = nil }
            )
        }
        .sheet(item: Binding(
            get: { syncService.pendingConflict },
            set: { if $0 == nil { syncService.pendingConflict = nil } }
        )) { conflict in
            ProgressConflictView(conflict: conflict) { keepLocal in
                Task { await syncService.resolveConflict(keepLocal: keepLocal) }
            }
            .sophiaSheetChrome()
        }
        .task {
            if auth.isSignedIn {
                await syncService.syncAtLaunch()
            }
        }
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn {
                Task { await syncService.syncAfterSignIn() }
            }
        }
        .onAppear {
            AnalyticsService.updateUserContext(
                language: languageManager.current,
                isPremium: storeVM.isPremium,
                onboardingCompleted: true
            )
            presentTrialEndingBannerIfNeeded()
            presentRetentionPaywallIfNeeded()
            // ATT est demandée dès l'ouverture de l'app (voir SophiaApp), plus ici.
            guard HomeCardPresentation.style == .legacy else { return }
            if !progressManager.hasSeenSwipeTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showSwipeTutorial = true
                    }
                }
            }
        }
        .onChange(of: storeVM.trialExpiresInOneDay) { _, _ in
            presentTrialEndingBannerIfNeeded()
        }
        .onChange(of: storeVM.willNotRenew) { _, _ in
            presentRetentionPaywallIfNeeded()
        }
        .onChange(of: storeVM.isPremium) { _, isPremium in
            AnalyticsService.updateUserContext(
                language: languageManager.current,
                isPremium: isPremium,
                onboardingCompleted: true
            )
        }
        // Both paths matter: `onChange` for a link that arrives while home is on screen,
        // and `task` for one that was parked during the onboarding — `onChange` does not
        // replay the value the view was born with.
        .onChange(of: router.token) { _, _ in
            openPendingDeepLink()
        }
        .task {
            openPendingDeepLink()
        }
        .trackAnalyticsLifecycle(isPremium: storeVM.isPremium)
    }

    /// Offers the retention price to someone who has cancelled but is still inside the
    /// period they have.
    ///
    /// Only when the store says the subscription will not renew. A reader whose trial
    /// is simply running its course is left alone: they were about to pay 39,99 €, and
    /// showing them 14,99 € would cost the difference for nothing.
    ///
    /// Once, ever. A cancellation that has been answered with an offer and refused is
    /// answered; re-asking on every launch of the remaining period would be nagging
    /// someone who is already paying us.
    private func presentRetentionPaywallIfNeeded() {
        guard storeVM.willNotRenew, paywallContext == nil, pendingCourse == nil else { return }
        let defaults = UserDefaults.standard
        let key = "sophia_retention_offer_shown"
        guard !defaults.bool(forKey: key) else { return }
        defaults.set(true, forKey: key)
        paywallContext = .retention
    }

    /// In-app only: tiny banner the calendar day before trial end, once per day, auto-hides in 1s.
    private func presentTrialEndingBannerIfNeeded() {
        guard auth.isSignedIn, storeVM.trialExpiresInOneDay, !showTrialEndingBanner else { return }
        let defaults = UserDefaults.standard
        let key = "sophia_trial_ending_banner_day"
        let day = Self.dayKey(for: Date())
        if defaults.string(forKey: key) == day { return }
        defaults.set(day, forKey: key)
        withAnimation(.easeIn(duration: 0.2)) {
            showTrialEndingBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.25)) {
                showTrialEndingBanner = false
            }
        }
    }

    private static func dayKey(for date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    private func courseSourceForCurrentTab() -> String {
        switch selectedTab {
        case 0:
            switch HomeCardPresentation.style {
            case .legacy: return "home_legacy"
            case .tinder: return "home_tinder"
            case .tiktok: return "home_tiktok"
            }
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

    private func openPendingDeepLink() {
        guard let courseId = router.pendingCourseId else { return }
        guard let course = ContentCatalog.course(withId: courseId) else {
            // Unknown id: drop it rather than retry it on every appearance.
            router.discard()
            return
        }
        _ = router.consume()
        selectedTab = 0
        explicitCourseSource = "deep_link"
        AnalyticsService.trackDeepLinkOpened(courseId: courseId)
        selectedCourse = course
    }
}
