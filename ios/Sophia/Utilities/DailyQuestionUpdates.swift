import SwiftUI

/// Garde la question du jour à jour (notifications et widget) depuis l'écran principal :
/// au lancement, au retour au premier plan, et quand l'abonnement, la langue ou les cours
/// lus changent. À part pour ne pas alourdir le corps de `ContentView`.
private struct DailyQuestionUpdatesModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(LanguageManager.self) private var languageManager
    let store: StoreViewModel
    let progressManager: ProgressManager

    func body(content: Content) -> some View {
        content
            .task { DailyCourseReminder.refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { DailyCourseReminder.refresh() }
            }
            .onChange(of: languageManager.current) { _, _ in DailyCourseReminder.refresh() }
            .onChange(of: store.isPremium) { _, _ in DailyCourseReminder.refresh() }
            .onChange(of: store.isInFreeTrial) { _, _ in DailyCourseReminder.refresh() }
            .onChange(of: progressManager.completedCount) { _, _ in DailyCourseReminder.refresh() }
    }
}

extension View {
    func dailyQuestionUpdates(store: StoreViewModel, progressManager: ProgressManager) -> some View {
        modifier(DailyQuestionUpdatesModifier(store: store, progressManager: progressManager))
    }
}
