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
    /// Audio mode unlock (listen, queue, download). Falls back to an `audio` offering, which
    /// does not need to exist: the current offering is sold first, like every context.
    case audio = "audio"
    /// Anti-scroll (TikTok blocker) unlock, from the home badge, the profile card or the
    /// blocker settings. Like `audio`, its `blocker` offering does not need to exist.
    case blocker = "blocker"

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
/// - `.quizz` → `SophiaQuizPaywall` (forgetting curve with and without quizzes, what PRO unlocks).
/// - `.debloquerCours` → `SophiaCourseUnlockPaywall` (locked course, countdown, « OU » Sophia PRO).
/// - `.audio` → `SophiaAudioPaywall` (sells listening: lock screen, French and English, offline).
/// - `.blocker` → `SophiaBlockerPaywall` (take back your time with the anti-scroll, what PRO unlocks).
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
        case .audio:
            SophiaAudioPaywall(
                store: store,
                course: course,
                onPurchased: onPurchased,
                onRestored: onRestored,
                onDismissed: onDismissed
            )
        case .blocker:
            SophiaBlockerPaywall(
                store: store,
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
