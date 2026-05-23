import SwiftUI
import RevenueCat
import RevenueCatUI

/// Identifiers for each offering configured in the RevenueCat dashboard.
/// Each one mirrors the same underlying products but can be styled / worded
/// differently from the RC dashboard without redeploying.
enum SophiaPaywallContext: String, Identifiable {
    case finOnboarding = "fin_onboarding"
    case offreDiscount = "offre_discount"
    case quizz = "quizz"
    case coursGratuit = "cours_gratuit"
    case matiereBlockHistoire = "matiere_block_histoire"
    case matiereBlockSciences = "matiere_block_sciences"
    case matiereBlockLitterature = "matiere_block_litterature"
    case matiereBlockArt = "matiere_block_art"
    case matiereBlockMythologie = "matiere_block_mythologie"
    case matiereBlockMondeActuel = "matiere_block_monde_actuel"

    var id: String { rawValue }

    /// Returns the per-subject "matière bloquée" paywall identifier.
    static func matiereBlock(for subject: Subject) -> SophiaPaywallContext {
        switch subject {
        case .histoire: return .matiereBlockHistoire
        case .sciences: return .matiereBlockSciences
        case .litterature: return .matiereBlockLitterature
        case .art: return .matiereBlockArt
        case .mythologie: return .matiereBlockMythologie
        case .comprendreLeMonde: return .matiereBlockMondeActuel
        }
    }
}

/// Wrapper around `RevenueCatUI.PaywallView` that loads a specific offering by
/// identifier and falls back to the default (current) offering if it can't be
/// found — e.g. while offerings are still loading or if the dashboard hasn't
/// been configured yet.
struct SophiaPaywallView: View {
    let context: SophiaPaywallContext
    /// Offering id tried if the primary `context` offering isn't found in RC.
    /// Defaults to `cours_gratuit` for the new "matière bloquée" paywalls so the
    /// user always sees a working paywall even before the dashboard is configured.
    var fallbackContext: SophiaPaywallContext? = .coursGratuit
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    @State private var offering: Offering?
    @State private var loaded: Bool = false

    var body: some View {
        Group {
            if let offering {
                PaywallView(offering: offering)
                    .onPurchaseCompleted { _ in onPurchased() }
                    .onRestoreCompleted { _ in onRestored() }
                    .onRequestedDismissal { onDismissed?() }
            } else if loaded {
                // Fallback: use the default current offering.
                PaywallView()
                    .onPurchaseCompleted { _ in onPurchased() }
                    .onRestoreCompleted { _ in onRestored() }
                    .onRequestedDismissal { onDismissed?() }
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView().tint(.white)
                }
                .task { await resolveOffering() }
            }
        }
    }

    private func resolveOffering() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            let id = context.rawValue
            var resolved = offerings.all[id] ?? offerings.offering(identifier: id)
            if resolved == nil, let fallback = fallbackContext, fallback != context {
                let fid = fallback.rawValue
                resolved = offerings.all[fid] ?? offerings.offering(identifier: fid)
                #if DEBUG
                print("[SophiaPaywall] '\(id)' not found — falling back to '\(fid)': \(resolved?.identifier ?? "nil")")
                #endif
            }
            #if DEBUG
            let available = offerings.all.keys.joined(separator: ", ")
            print("[SophiaPaywall] looking for '\(id)' — available offerings: [\(available)] — current: \(offerings.current?.identifier ?? "nil") — resolved: \(resolved?.identifier ?? "nil")")
            #endif
            offering = resolved
        } catch {
            #if DEBUG
            print("[SophiaPaywall] failed to fetch offerings: \(error)")
            #endif
            offering = nil
        }
        loaded = true
    }
}
