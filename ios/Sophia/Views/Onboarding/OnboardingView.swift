import SwiftUI
import RevenueCat

struct OnboardingView: View {
    /// Flip to `true` to restore the custom native paywall at the end of onboarding.
    private let useNativeOnboardingPaywall = false

    @Environment(LanguageManager.self) private var languageManager

    @State private var viewModel = OnboardingViewModel()
    @State private var storeVM = StoreViewModel()
    let onComplete: () -> Void
    @State private var showSpecialOffer: Bool = false
    @State private var displayedScreen: Int = 0
    @State private var incomingScreen: Int? = nil
    @State private var slideOffset: CGFloat = 0
    @State private var finOnboardingOffering: Offering?
    @State private var finOnboardingOfferingResolved = false
    @State private var showRCPaywall = false
    @State private var didFinishOnboarding = false
    @State private var didTrackOnboardingStart = false
    @State private var sawOnboardingPaywall = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                screenView(for: displayedScreen, in: geo.size)
                    .zIndex(0)

                if let incoming = incomingScreen {
                    screenView(for: incoming, in: geo.size)
                        .offset(x: slideOffset)
                        .zIndex(1)
                }

                if showSpecialOffer {
                    OnboardingSpecialOfferView(
                        store: storeVM,
                        onSubscribed: {
                            showSpecialOffer = false
                            finishOnboarding()
                        },
                        onSkip: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                showSpecialOffer = false
                            }
                            finishOnboarding()
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(3)
                }
            }
            .overlay(alignment: .top) {
                if showsOnboardingProgressDots {
                    OnboardingProgressDots(current: onboardingProgressIndex, total: Self.progressQuestionScreens.count)
                        .padding(.top, 10)
                        .allowsHitTesting(false)
                        .zIndex(10)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .preferredColorScheme(.light)
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showRCPaywall, onDismiss: finishOnboarding) {
            if let finOnboardingOffering {
                SophiaPaywallView(
                    context: .finOnboarding,
                    preloadedOffering: finOnboardingOffering,
                    onPurchased: finishOnboarding,
                    onRestored: finishOnboarding,
                    onDismissed: finishOnboarding
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
        }
        .onChange(of: displayedScreen) { _, screen in
            if screen == 12, !useNativeOnboardingPaywall {
                prefetchFinOnboardingOffering()
            }
        }
        .onChange(of: incomingScreen) { _, screen in
            if screen == 12, !useNativeOnboardingPaywall {
                prefetchFinOnboardingOffering()
            }
        }
        .onChange(of: displayedScreen) { _, screen in
            trackOnboardingScreen(screen)
        }
        .onAppear {
            if !didTrackOnboardingStart {
                didTrackOnboardingStart = true
                AnalyticsService.trackOnboardingStarted()
                AnalyticsService.trackOnboardingStepViewed(stepIndex: 0)
            }
        }
    }

    private func trackOnboardingScreen(_ screen: Int) {
        AnalyticsService.trackOnboardingStepViewed(stepIndex: screen)
    }

    @ViewBuilder
    private func screenView(for screen: Int, in size: CGSize) -> some View {
        let slideSettled = displayedScreen == screen && incomingScreen == nil
        ZStack {
            OnboardingScreenColors.background(for: screen)
                .ignoresSafeArea()

            Group {
            switch screen {
                case 0:
                    OnboardingIntroScreen(onNext: advance)
                case 1:
                    OnboardingLanguageScreen(onNext: advance)
                case 2:
                    OnboardingWelcomeScreen(onNext: advance)
                case 3:
                    OnboardingPhoneTimeScreen(viewModel: viewModel, onNext: advance)
                case 4:
                    OnboardingWastedTimeScreen(viewModel: viewModel, onNext: advance)
                case 5:
                    OnboardingObjectivesScreen(viewModel: viewModel, onNext: advance)
                case 6:
                    OnboardingInterestsScreen(viewModel: viewModel, onNext: advance)
                case 7:
                    OnboardingShowcaseCoursesScreen(onNext: advance)
                case 8:
                    OnboardingDailyGoalScreen(viewModel: viewModel, onNext: advance)
                case 9:
                    OnboardingProjectionScreen(viewModel: viewModel, onNext: advance)
                case 10:
                    OnboardingShowcaseQuizScreen(onNext: advance)
                case 11:
                    OnboardingShowcaseCollectionsScreen(onNext: advance)
                case 12:
                    OnboardingLoadingScreen(viewModel: viewModel, onNext: loadingScreenCompleted)
                case 13:
                    OnboardingProgramScreen(viewModel: viewModel, onNext: advance)
                case 14:
                    OnboardingPremiumGiftScreen(onNext: advance)
                case 15:
                    OnboardingPremiumTrialTimelineScreen(onUnlockTrial: trialTimelineCompleted)
                case 16:
                    nativePaywallScreen
                default:
                    EmptyView()
            }
            }
        }
        .frame(width: size.width, height: size.height)
        .environment(\.onboardingSlideSettled, slideSettled)
    }

    @ViewBuilder
    private var nativePaywallScreen: some View {
        OnboardingNativePaywallView(
            store: storeVM,
            onPurchase: { plan in
                Task {
                    guard let package = packageFor(plan: plan) else {
                        #if DEBUG
                        print("[OnboardingPaywall] no package found for plan \(plan)")
                        #endif
                        return
                    }
                    let success = await storeVM.purchase(package: package)
                    if success {
                        AnalyticsService.trackPurchaseCompleted(
                            context: SophiaPaywallContext.finOnboarding.rawValue,
                            offeringId: storeVM.offerings?.current?.identifier,
                            packageId: package.identifier
                        )
                        await MainActor.run { finishOnboarding() }
                    }
                }
            },
            onRestore: {
                Task {
                    await storeVM.restore()
                    if storeVM.isPremium {
                        await MainActor.run { finishOnboarding() }
                    }
                }
            },
            onClose: finishOnboarding
        )
    }

    private func loadingScreenCompleted() {
        if storeVM.isPremium {
            finishOnboarding()
            return
        }
        advance()
    }

    private func trialTimelineCompleted() {
        if useNativeOnboardingPaywall {
            advance()
        } else {
            presentOnboardingPaywall()
        }
    }

    private func presentOnboardingPaywall() {
        if storeVM.isPremium {
            finishOnboarding()
            return
        }

        Task {
            if !finOnboardingOfferingResolved {
                let offering = await SophiaPaywallView.loadOffering(for: .finOnboarding)
                await MainActor.run {
                    finOnboardingOffering = offering
                    finOnboardingOfferingResolved = true
                }
            }

            await MainActor.run {
                if finOnboardingOffering != nil {
                    sawOnboardingPaywall = true
                    showRCPaywall = true
                } else {
                    finishOnboarding()
                }
            }
        }
    }

    private func packageFor(plan: OnboardingNativePaywallView.Plan) -> RevenueCat.Package? {
        switch plan {
        case .yearly:
            return storeVM.annualPackage
        case .monthly:
            return storeVM.monthlyPackage
        }
    }

    private func prefetchFinOnboardingOffering() {
        guard !finOnboardingOfferingResolved else { return }
        Task {
            let offering = await SophiaPaywallView.loadOffering(for: .finOnboarding)
            await MainActor.run {
                finOnboardingOffering = offering
                finOnboardingOfferingResolved = true
            }
        }
    }

    private func finishOnboarding() {
        guard !didFinishOnboarding else { return }
        didFinishOnboarding = true
        showSpecialOffer = false
        showRCPaywall = false
        AnalyticsService.trackOnboardingCompleted(
            sawPaywall: sawOnboardingPaywall,
            isPremiumAtExit: storeVM.isPremium
        )
        viewModel.completeOnboarding()
        onComplete()
    }

    /// Onboarding value screens that show progress dots (excludes intro, language, loading, program, and paywalls).
    private static let progressQuestionScreens = Array(2...11)

    private var showsOnboardingProgressDots: Bool {
        let active = incomingScreen ?? displayedScreen
        return Self.progressQuestionScreens.contains(active)
    }

    private var onboardingProgressIndex: Int {
        let active = incomingScreen ?? displayedScreen
        return Self.progressQuestionScreens.firstIndex(of: active) ?? 0
    }

    private func advance() {
        OnboardingHaptics.slideTransition()
        let fromScreen = viewModel.currentScreen
        if fromScreen == 6 {
            viewModel.persistInterests()
            AnalyticsService.trackOnboardingInterestsSet(viewModel.interests)
        }

        // ATT après le 1er écran d'onboarding (pas au lancement de l'app).
        if fromScreen == 0 {
            MetaAdsService.requestTrackingAuthorizationAfterFirstScreen()
        }

        let to = fromScreen + 1
        let width = UIScreen.main.bounds.width

        incomingScreen = to
        slideOffset = width
        viewModel.nextScreen()

        withAnimation(.easeInOut(duration: 0.4)) {
            slideOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            displayedScreen = to
            incomingScreen = nil
            slideOffset = 0
        }
    }
}

struct OnboardingProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? BrutalPalette.ink : BrutalPalette.ink.opacity(0.15))
                    .frame(width: i == current ? 28 : 10, height: 5)
                    .animation(.spring(response: 0.3), value: current)
            }
        }
    }
}
