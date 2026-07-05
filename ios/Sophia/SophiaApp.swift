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
    }

    var body: some Scene {
        WindowGroup {
            if showOnboarding {
                OnboardingView(onComplete: {
                    withAnimation(.spring(response: 0.5)) {
                        showOnboarding = false
                    }
                })
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
            if let courseId = WidgetDeepLink.courseId(from: url) {
                deepLinkCourseId = courseId
            }
        }
    }
}
