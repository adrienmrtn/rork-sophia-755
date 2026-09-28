import SwiftUI

/// Identifiers for each paywall context, rendered by **native** SwiftUI paywalls rather than
/// RevenueCat dashboard templates.
///
/// The price shown and charged always comes from the offering RevenueCat currently serves
/// (`offerings.current`, which is what experiments swap), so a customer sees one price
/// everywhere. The offering of the same name as the context is only a fallback when the
/// current offering has no annual package; analytics keep the context in `context`.
enum SophiaPaywallContext: String, Identifiable {
    case finOnboarding = "fin_onboarding"
    case offreDiscount = "offre_discount"
    case debloquerCours = "debloquer_cours"
    case quizz = "quizz"
    /// Training-tab unlock. Its own analytics funnel; its fallback offering is `quizz`
    /// (see `offeringIdentifier`).
    case entrainement = "entrainement"

    var id: String { rawValue }

    /// Fallback RevenueCat offering identifier for this context (see
    /// `StoreViewModel.displayedOffering(forContextIdentifier:)`). Usually the raw value,
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
/// - `.offreDiscount` → `SophiaDiscountPaywall` (flash sale on the `offre_discount` offering).
/// - `.entrainement` → `SophiaTrainingPaywall` (sells the spaced-repetition training method).
/// - `.quizz` → `SophiaQuizPaywall` (auto-playing quiz demo, FAQ, activate-trial CTA).
/// - `.debloquerCours` → `SophiaCourseUnlockPaywall` (rating, 6-courses/day stat, reviews, countdown).
/// - `.finOnboarding` → `SophiaStandardPaywall` (single annual plan, price and trial from the store).
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
        paywall
            .preferredColorScheme(.light)
    }

    @ViewBuilder
    private var paywall: some View {
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
