import SwiftUI

struct AnalyticsLifecycleModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    let isPremium: Bool
    var appOpenSource: String = "cold_start"

    func body(content: Content) -> some View {
        content
            .onAppear { handleBecameActive() }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                handleBecameActive()
            }
    }

    private func handleBecameActive() {
        AnalyticsService.trackAppOpened(source: appOpenSource)
        AnalyticsService.trackSessionIfNeeded(isPremium: isPremium)
        AnalyticsService.updateUserContext(
            language: LanguageManager.shared.current,
            isPremium: isPremium,
            onboardingCompleted: OnboardingViewModel.isOnboardingCompleted
        )
    }
}

extension View {
    func trackAnalyticsLifecycle(isPremium: Bool, appOpenSource: String = "cold_start") -> some View {
        modifier(AnalyticsLifecycleModifier(isPremium: isPremium, appOpenSource: appOpenSource))
    }
}
