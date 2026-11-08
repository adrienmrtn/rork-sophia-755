import SwiftUI

/// L'accueil des 5 onglets historiques : le fil TikTok. Les présentations « legacy » et
/// « Tinder » ont été retirées avec la nouvelle navigation (prompt 2) ; la nouvelle génération
/// a son propre fil, `HomeFeedView`.
struct HomeView: View {
    let progressManager: ProgressManager
    let discountManager: DiscountOfferManager
    var isPremium: Bool = false
    @Binding var selectedCourse: Course?
    @Binding var autoSwipeCourseId: String?
    var onShowDiscountPaywall: (() -> Void)? = nil
    var onOpenMyCourses: (() -> Void)? = nil
    /// The anti-scroll badge beside the streak. Presented by `ContentView`.
    var onOpenAntiScroll: (() -> Void)? = nil

    var body: some View {
        HomeViewTikTok(
            progressManager: progressManager,
            discountManager: discountManager,
            isPremium: isPremium,
            selectedCourse: $selectedCourse,
            autoSwipeCourseId: $autoSwipeCourseId,
            onShowDiscountPaywall: onShowDiscountPaywall,
            onOpenMyCourses: onOpenMyCourses,
            onOpenAntiScroll: onOpenAntiScroll
        )
    }
}
