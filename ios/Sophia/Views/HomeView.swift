import SwiftUI

struct HomeView: View {
    let progressManager: ProgressManager
    let discountManager: DiscountOfferManager
    var isPremium: Bool = false
    @Binding var selectedCourse: Course?
    @Binding var autoSwipeCourseId: String?
    var onShowDiscountPaywall: (() -> Void)? = nil
    /// Only the TikTok home carries the history button; the other two presentations are
    /// kept for rollback and are not part of this feature.
    var onOpenMyCourses: (() -> Void)? = nil

    var body: some View {
        switch HomeCardPresentation.style {
        case .legacy:
            HomeViewLegacy(
                progressManager: progressManager,
                discountManager: discountManager,
                isPremium: isPremium,
                selectedCourse: $selectedCourse,
                autoSwipeCourseId: $autoSwipeCourseId,
                onShowDiscountPaywall: onShowDiscountPaywall
            )
        case .tinder:
            HomeViewTinder(
                progressManager: progressManager,
                discountManager: discountManager,
                isPremium: isPremium,
                selectedCourse: $selectedCourse,
                autoSwipeCourseId: $autoSwipeCourseId,
                onShowDiscountPaywall: onShowDiscountPaywall
            )
        case .tiktok:
            HomeViewTikTok(
                progressManager: progressManager,
                discountManager: discountManager,
                isPremium: isPremium,
                selectedCourse: $selectedCourse,
                autoSwipeCourseId: $autoSwipeCourseId,
                onShowDiscountPaywall: onShowDiscountPaywall,
                onOpenMyCourses: onOpenMyCourses
            )
        }
    }
}
