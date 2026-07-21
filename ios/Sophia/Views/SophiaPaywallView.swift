import SwiftUI

/// Identifiers for each paywall context. Each maps to a RevenueCat offering of the same
/// name (so analytics + product attribution stay per-context) but is now rendered by a
/// **native** SwiftUI paywall rather than a RevenueCat dashboard template.
enum SophiaPaywallContext: String, Identifiable {
    case finOnboarding = "fin_onboarding"
    case offreDiscount = "offre_discount"
    case debloquerCours = "debloquer_cours"
    case quizz = "quizz"

    var id: String { rawValue }
}

/// Dispatcher that renders the appropriate native paywall for a given context.
///
/// - `.offreDiscount` → `SophiaDiscountPaywall` (flash sale, `special_promo`, 19,99 €/an).
/// - everything else → `SophiaStandardPaywall` (single annual plan, 39,99 €/an, 3-day trial).
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
        case .quizz, .debloquerCours, .finOnboarding:
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
