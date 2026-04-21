import SwiftUI
import RevenueCat

@main
struct SophiaApp: App {
    @State private var showOnboarding: Bool = !OnboardingViewModel.isOnboardingCompleted

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
                ContentView()
            }
        }
    }
}
