import SwiftUI
import RevenueCat
import GoogleSignIn

@main
struct SophiaApp: App {
    // Pont UIKit : FacebookCore s'initialise dans didFinishLaunching / applicationDidBecomeActive.
    @UIApplicationDelegateAdaptor(SophiaAppDelegate.self) private var appDelegate

    @State private var languageManager = LanguageManager.shared
    @State private var appearanceManager = AppearanceManager.shared
    @State private var showOnboarding: Bool = !OnboardingViewModel.isOnboardingCompleted
    @State private var deepLinkCourseId: String?

    init() {
        #if DEBUG
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: AppConfig.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY)
        #else
        Purchases.configure(withAPIKey: AppConfig.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY)
        #endif
        AnalyticsService.configure()
        AuthService.shared.start()
        // Les boutons dans un `ScrollView` (ex. « Commencer » sur les cartes accueil) répondent
        // au tap immédiatement, sans le délai UIKit qui obligeait à attendre la fin du
        // défilement/snap avant que le tap ne soit pris en compte.
        UIScrollView.appearance().delaysContentTouches = false
        // Belt-and-suspenders: `PlusJakartaSans.ttf` is already declared in `UIAppFonts`
        // (Info.plist), which the system loads automatically at launch, but registering it
        // explicitly here too guarantees it's available before the very first screen draws
        // — the whole design system (`DS.title`/`DS.sans`) now renders in it, not just the
        // paywall this was originally added for.
        PaywallFonts.registerIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingV2View(onComplete: {
                        withAnimation(.spring(response: 0.5)) {
                            showOnboarding = false
                        }
                    })
                    .trackAnalyticsLifecycle(isPremium: false)
                } else {
                    ContentView(
                        onResetOnboarding: {
                            UserDefaults.standard.set(false, forKey: "sophia_onboarding_completed")
                            UserDefaults.standard.set(false, forKey: "sophia_special_offer_seen")
                            withAnimation(.spring(response: 0.5)) {
                                showOnboarding = true
                            }
                        },
                        deepLinkCourseId: $deepLinkCourseId
                    )
                }
            }
            .environment(languageManager)
            .environment(appearanceManager)
            .environment(AuthService.shared)
            .environment(\.locale, languageManager.locale)
            .preferredColorScheme(appearanceManager.preference.preferredColorScheme)
            .animation(.easeInOut(duration: 0.25), value: appearanceManager.preference)
            .onAppear {
                // ATT dès l'ouverture de l'app (avant/pendant l'onboarding), pas après.
                MetaAdsService.requestTrackingAuthorizationAtLaunch()
            }
            .onOpenURL { url in
                // Callback Google Sign-In (reversed client ID) en priorité.
                if GIDSignIn.sharedInstance.handle(url) {
                    return
                }
                // Callbacks Meta (fb…) + deep links Sophia (`sophia://…`).
                MetaAdsService.handleOpenURL(url)
                if let courseId = SophiaDeepLink.courseId(from: url) {
                    deepLinkCourseId = courseId
                }
            }
        }
    }
}
