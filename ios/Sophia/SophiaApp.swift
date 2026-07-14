import SwiftUI
import RevenueCat

@main
struct SophiaApp: App {
    @State private var languageManager = LanguageManager.shared
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
        // FacebookCore : lecture App ID / Client Token via Info.plist uniquement.
        MetaAdsService.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingView(onComplete: {
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
            .environment(\.locale, languageManager.locale)
            .onOpenURL { url in
                // Callbacks Meta (fb…) + deep links Sophia (`sophia://…`).
                MetaAdsService.handleOpenURL(url)
                if let courseId = SophiaDeepLink.courseId(from: url) {
                    deepLinkCourseId = courseId
                }
            }
        }
    }
}
