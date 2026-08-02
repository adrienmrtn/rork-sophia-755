import SwiftUI

/// Identifiers for each paywall context. Each maps to a RevenueCat offering of the same
/// name (so analytics + product attribution stay per-context) but is now rendered by a
/// **native** SwiftUI paywall rather than a RevenueCat dashboard template.
enum SophiaPaywallContext: String, Identifiable {
    case finOnboarding = "fin_onboarding"
    case offreDiscount = "offre_discount"
    case debloquerCours = "debloquer_cours"
    case quizz = "quizz"
    /// Training-tab unlock. Its own analytics funnel, but purchases still attribute to the
    /// `quizz` RevenueCat offering (see `offeringIdentifier`).
    case entrainement = "entrainement"

    var id: String { rawValue }

    /// RevenueCat offering identifier used for purchase attribution. Usually the raw value,
    /// but `.entrainement` reuses the shared `quizz` offering.
    var offeringIdentifier: String {
        switch self {
        case .entrainement: return SophiaPaywallContext.quizz.rawValue
        default: return rawValue
        }
    }
}

/// Dispatcher that renders the appropriate native paywall for a given context.
///
/// - `.offreDiscount` → `SophiaDiscountPaywall` (flash sale, `offre_discount`, 19,99 €/an).
/// - `.entrainement` → `SophiaTrainingPaywall` (sells the spaced-repetition training method).
/// - `.quizz` → `SophiaQuizPaywall` (auto-playing quiz demo, FAQ, activate-trial CTA).
/// - `.debloquerCours` → `SophiaCourseUnlockPaywall` (rating, 6-courses/day stat, reviews, countdown).
/// - `.finOnboarding` → `SophiaStandardPaywall` (single annual plan, 39,99 €/an, 3-day trial).
struct SophiaPaywallView: View {
    let context: SophiaPaywallContext
    let store: StoreViewModel
    var course: Course? = nil
    var discountManager: DiscountOfferManager? = nil
    /// Seconds until the daily free course resets, forwarded to the course-unlock paywall.
    var secondsUntilReset: Int? = nil
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    var body: some View {
        switch context {
        case .offreDiscount:
            SophiaDiscountPaywall(
                store: store,
                discountManager: discountManager,
                onPurchased: onPurchased,
                onRestored: onRestored,
                onDismissed: onDismissed
            )
        case .entrainement:
            SophiaTrainingPaywall(
                store: store,
                onPurchased: onPurchased,
                onRestored: onRestored,
                onDismissed: onDismissed
            )
        case .quizz:
            SophiaQuizPaywall(
                store: store,
                onPurchased: onPurchased,
                onRestored: onRestored,
                onDismissed: onDismissed
            )
        case .debloquerCours:
            SophiaCourseUnlockPaywall(
                store: store,
                course: course,
                secondsUntilReset: secondsUntilReset,
                onPurchased: onPurchased,
                onRestored: onRestored,
                onDismissed: onDismissed
            )
        case .finOnboarding:
            SophiaStandardPaywall(
                context: context,
                store: store,
                course: course,
                secondsUntilReset: secondsUntilReset,
                onPurchased: onPurchased,
                onRestored: onRestored,
                onDismissed: onDismissed
            )
        }
    }
}
