import SwiftUI
import RevenueCatUI

struct ContentView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AppearanceManager.self) private var appearance
    @Environment(AuthService.self) private var auth
    @Environment(\.scenePhase) private var scenePhase
    var onResetOnboarding: (() -> Void)? = nil
    let router: DeepLinkRouter

    @State private var progressManager = ProgressManager()
    @State private var syncService = ProgressSyncService.shared
    @State private var storeVM = StoreViewModel()
    @State private var discountManager = DiscountOfferManager()
    @State private var blocker = TikTokBlockerManager.shared
    @State private var selectedTab: Int = 0
    @State private var selectedCourse: Course? = nil
    @State private var paywallContext: SophiaPaywallContext? = nil

    @State private var showSwipeTutorial: Bool = false
    @State private var pendingCourse: Course? = nil
    @State private var autoSwipeCourseId: String? = nil
    @State private var showTrialEndingBanner: Bool = false
    @State private var showMyCourses: Bool = false
    /// Full audio player, opened from the mini-player above the tab bar.
    @State private var showAudioPlayer: Bool = false
    /// « Active l'anti-scroll », the sheet before the blocker is turned on (home badge).
    @State private var showAntiScrollIntro: Bool = false
    /// The blocker settings, opened from the home badge once the reader is a member.
    @State private var showBlockerSettings: Bool = false

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
                            discountManager.markShownToday()
                            paywallContext = .offreDiscount
                        },
                        onOpenMyCourses: { showMyCourses = true },
                        onOpenAntiScroll: openAntiScroll
                    )
                    .audioMiniPlayerInset(onOpen: openAudioPlayer)
                }

                Tab(languageManager.text("tab.library"), systemImage: "books.vertical.fill", value: 1) {
                    libraryTab
                        .audioMiniPlayerInset(onOpen: openAudioPlayer)
                }

                // The path took the collections' slot; the former collections pages are gone.
                Tab(languageManager.text("tab.path"), systemImage: "point.bottomleft.forward.to.point.topright.scurvepath.fill", value: 2) {
                    pathTab
                        .audioMiniPlayerInset(onOpen: openAudioPlayer)
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
                    .audioMiniPlayerInset(onOpen: openAudioPlayer)
                }

                Tab(languageManager.text("tab.profile"), systemImage: "person.fill", value: 4) {
                    ProfileView(
                        progressManager: progressManager,
                        store: storeVM,
                        selectedCourse: $selectedCourse,
                        onShowPaywall: {
                            paywallContext = .debloquerCours
                        },
                        onShowBlockerPaywall: {
                            paywallContext = .blocker
                        },
                        onResetOnboarding: onResetOnboarding
                    )
                    .audioMiniPlayerInset(onOpen: openAudioPlayer)
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
                pendingCourse = course
            }
            .fullScreenCover(item: $pendingCourse) { course in
                CourseView(
                    course: course,
                    progressManager: progressManager,
                    store: storeVM,
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
                clearSelectionIfDismissed(newValue)
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

            // Shield-originated visit paid off: TikTok is open, say so and offer the
            // way back. Waits for the reader to be gone so it is not drawn under it.
            if blocker.showUnlockedScreen, pendingCourse == nil {
                TikTokUnlockedView(
                    onBackToTikTok: {
                        _ = blocker.openTikTok()
                        blocker.endSession()
                    },
                    onStay: { blocker.endSession() }
                )
                .transition(.opacity)
                .zIndex(90)
            }

        }
        .animation(.easeInOut(duration: 0.3), value: blocker.showUnlockedScreen)
        .animation(.easeInOut(duration: 0.3), value: discountManager.isGiftPending)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: discountManager.isActive)
        .animation(.easeInOut(duration: 0.25), value: showTrialEndingBanner)
        .fullScreenCover(isPresented: $showMyCourses) {
            MyCoursesView(
                progressManager: progressManager,
                onOpenCourse: { course in
                    showMyCourses = false
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
                course: paywallCourse(for: context),
                discountManager: discountManager,
                secondsUntilReset: context == .debloquerCours ? progressManager.secondsUntilDailyReset() : nil,
                onPurchased: {
                    if context == .offreDiscount { discountManager.markExpired() }
                    paywallContext = nil
                    if context == .audio { playAudioAfterPurchase() }
                    if context == .blocker { openBlockerSettingsAfterPurchase() }
                },
                onRestored: { paywallContext = nil },
                onDismissed: { paywallContext = nil }
            )
        }
        .sheet(isPresented: $showAntiScrollIntro) {
            AntiScrollIntroSheet(onActivate: activateAntiScroll)
                .sophiaSheetChrome()
        }
        .fullScreenCover(isPresented: $showBlockerSettings) {
            TikTokBlockerSettingsView(
                store: storeVM,
                onShowPaywall: {
                    // The settings cover has to be gone before the paywall cover comes up,
                    // or the two presentations race and neither appears.
                    showBlockerSettings = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        paywallContext = .blocker
                    }
                },
                presentedAsCover: true
            )
            .sophiaColorScheme()
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
            presentTrialEndingBannerIfNeeded()
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
        // Both paths matter: `onChange` for a link that arrives while home is on screen,
        // and `task` for one that was parked during the onboarding — `onChange` does not
        // replay the value the view was born with.
        .onChange(of: router.token) { _, _ in
            openPendingDeepLink()
            openBlockerCourseIfNeeded()
        }
        .task {
            openPendingDeepLink()
        }
        // The blocker's two foreground duties: keep the shield in line with the stored
        // state (an unlock window may have ended while we were away), and answer a tap
        // on the shield by opening a course straight away.
        .task {
            blocker.syncLanguage(languageManager.current)
            blocker.reconcileShield()
            openBlockerCourseIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            blocker.reconcileShield()
            openBlockerCourseIfNeeded()
        }
        .onChange(of: languageManager.current) { _, language in
            blocker.syncLanguage(language)
        }
        .dailyQuestionUpdates(store: storeVM, progressManager: progressManager)
        .courseAudioHost(
            store: storeVM,
            progressManager: progressManager,
            showPlayer: $showAudioPlayer,
            onShowPaywall: presentAudioPaywall
        )
    }

    // MARK: - Anti-scroll

    /// The home badge: the explainer while the blocker is off, its settings once it is on.
    private func openAntiScroll() {
        if blocker.isEnabled {
            showBlockerSettings = true
        } else {
            showAntiScrollIntro = true
        }
    }

    /// « Activer l'anti-scroll » on the explainer: a member goes to the settings to turn it
    /// on, a free reader meets the blocker paywall. The sheet goes first, then the cover.
    private func activateAntiScroll() {
        showAntiScrollIntro = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if storeVM.isPremium {
                showBlockerSettings = true
            } else {
                paywallContext = .blocker
            }
        }
    }

    /// Bought from the blocker paywall: straight to the switch, without a second tap.
    private func openBlockerSettingsAfterPurchase() {
        guard storeVM.isPremium else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            showBlockerSettings = true
        }
    }

    // MARK: - Audio

    private func openAudioPlayer() {
        showAudioPlayer = true
    }

    /// A free user asked for audio. From the full player (a subscription that lapsed), the
    /// sheet has to go first: a cover cannot be presented over it from here.
    private func presentAudioPaywall() {
        guard showAudioPlayer else {
            paywallContext = .audio
            return
        }
        showAudioPlayer = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            paywallContext = .audio
        }
    }

    /// The audio paywall shows the course the user wanted to hear.
    private func paywallCourse(for context: SophiaPaywallContext) -> Course? {
        guard context == .audio, let id = CourseAudioPlayer.shared.paywallCourseId else { return nil }
        return ContentCatalog.course(withId: id)
    }

    /// Bought from the audio paywall: play what they asked for, without a second tap.
    private func playAudioAfterPurchase() {
        let player = CourseAudioPlayer.shared
        player.isPremium = storeVM.isPremium
        guard storeVM.isPremium, let id = player.paywallCourseId else { return }
        player.requestPlay(courseId: id, source: "paywall_purchase")
    }

    private var libraryTab: some View {
        LibraryView(
            progressManager: progressManager,
            selectedCourse: $selectedCourse,
            isInFreeTrial: storeVM.isInFreeTrial
        )
    }

    private var pathTab: some View {
        LearningPathView(
            progressManager: progressManager,
            selectedCourse: $selectedCourse
        )
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

    private func clearSelectionIfDismissed(_ course: Course?) {
        if course == nil {
            selectedCourse = nil
        }
    }

    private static func dayKey(for date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    /// "Open Sophia" on the TikTok shield lands here. No home, no picker: the course is
    /// chosen and opened at once, and the reader shows its lock banner.
    private func openBlockerCourseIfNeeded() {
        guard blocker.consumePendingRequest() else { return }
        guard let course = blocker.startSession(candidate: blockerCandidateCourse) else { return }
        paywallContext = nil
        showMyCourses = false
        if let open = pendingCourse {
            if open.id == course.id { return }
            pendingCourse = nil
            selectedCourse = nil
        }
        selectedTab = 0
        // Any cover that was up needs to be gone before the reader is presented, or the
        // two presentations race and neither appears (same delay as `MyCoursesView`).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            selectedCourse = course
        }
    }

    /// The question of the day when it is still unread (every question has a quiz);
    /// otherwise the same recommendation as the home deck, restricted to courses that
    /// have a quiz: without one there is nothing to finish. Everything done: any course
    /// with a quiz, a re-read is still a read.
    private func blockerCandidateCourse() -> Course? {
        let isCompleted: (String) -> Bool = { progressManager.courseStatus(for: $0) == .completed }
        if let id = DailyQuestion.todayCourseId(language: languageManager.current, isCompleted: isCompleted),
           !isCompleted(id),
           let course = ContentCatalog.course(withId: id),
           course.hasQuiz {
            return course
        }
        let withQuiz = ContentCatalog.activeCourses.filter(\.hasQuiz)
        let deck = HomeDeckBuilder.deck(
            from: withQuiz,
            context: DeckContext.current(progressManager: progressManager),
            isCompleted: { progressManager.courseStatus(for: $0) == .completed }
        )
        return deck.first ?? withQuiz.randomElement()
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
        selectedCourse = course
    }
}
