import SwiftUI

struct HomeView: View {
    let progressManager: ProgressManager
    let discountManager: DiscountOfferManager
    var isPremium: Bool = false
    @Binding var selectedCourse: Course?
    @Binding var autoSwipeCourseId: String?
    var onShowDiscountPaywall: (() -> Void)? = nil

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
        case .feed:
            HomeViewFeed(
                progressManager: progressManager,
                discountManager: discountManager,
                isPremium: isPremium,
                selectedCourse: $selectedCourse,
                autoSwipeCourseId: $autoSwipeCourseId,
                onShowDiscountPaywall: onShowDiscountPaywall
            )
        }
    }
}
