import SwiftUI
import RevenueCat

@main
struct SophiaApp: App {
    @AppStorage("sophia_onboarding_completed") private var onboardingCompleted: Bool = false

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
            if !onboardingCompleted {
                OnboardingView(onComplete: {
                    withAnimation(.spring(response: 0.5)) {
                        onboardingCompleted = true
                    }
                })
            } else {
                ContentView()
            }
        }
    }
}
