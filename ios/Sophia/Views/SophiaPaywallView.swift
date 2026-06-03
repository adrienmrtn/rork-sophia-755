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

    /// Only matière-block paywalls fall back to `cours_gratuit` when RC isn't configured yet.
    static func fallback(for context: SophiaPaywallContext) -> SophiaPaywallContext? {
        switch context {
        case .matiereBlockHistoire, .matiereBlockSciences, .matiereBlockLitterature,
             .matiereBlockArt, .matiereBlockMythologie, .matiereBlockMondeActuel:
            return .coursGratuit
        default:
            return nil
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
    /// Only matière-block paywalls fall back to `cours_gratuit`; other contexts must match exactly.
    var fallbackContext: SophiaPaywallContext? = nil
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    @State private var offering: Offering?
    @State private var loaded: Bool = false

    private var resolvedFallback: SophiaPaywallContext? {
        fallbackContext ?? SophiaPaywallContext.fallback(for: context)
    }

    var body: some View {
        Group {
            if let offering {
                PaywallView(offering: offering)
                    .onPurchaseCompleted { _ in onPurchased() }
                    .onRestoreCompleted { _ in onRestored() }
                    .onRequestedDismissal { onDismissed?() }
            } else if loaded {
                if context == .finOnboarding || context == .coursGratuit || context == .offreDiscount {
                    PaywallView()
                        .onPurchaseCompleted { _ in onPurchased() }
                        .onRestoreCompleted { _ in onRestored() }
                        .onRequestedDismissal { onDismissed?() }
                } else {
                    paywallUnavailableView
                }
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
            if resolved == nil, let fallback = resolvedFallback, fallback != context {
                let fid = fallback.rawValue
                resolved = offerings.all[fid] ?? offerings.offering(identifier: fid)
                #if DEBUG
                print("[SophiaPaywall] '\(id)' not found — falling back to '\(fid)': \(resolved?.identifier ?? "nil")")
                #endif
            }
            if resolved == nil, context == .offreDiscount {
                resolved = offerings.current
                #if DEBUG
                print("[SophiaPaywall] 'offre_discount' not found — using current offering: \(resolved?.identifier ?? "nil")")
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

    private var paywallUnavailableView: some View {
        VStack(spacing: 16) {
            Text("Offre indisponible")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
            Text("Impossible de charger «\(context.rawValue)» pour le moment.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Fermer") { onDismissed?() }
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(.white, in: Capsule())
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}
