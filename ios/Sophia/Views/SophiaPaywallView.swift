import SwiftUI
import RevenueCat
import RevenueCatUI

/// Identifiers for each offering configured in the RevenueCat dashboard.
/// Each one mirrors the same underlying products but can be styled / worded
/// differently from the RC dashboard without redeploying.
enum SophiaPaywallContext: String {
    case finOnboarding = "fin_onboarding"
    case quizz = "quizz"
    case coursGratuit = "cours_gratuit"
}

/// Wrapper around `RevenueCatUI.PaywallView` that loads a specific offering by
/// identifier and falls back to the default (current) offering if it can't be
/// found — e.g. while offerings are still loading or if the dashboard hasn't
/// been configured yet.
struct SophiaPaywallView: View {
    let context: SophiaPaywallContext
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}

    @State private var offering: Offering?
    @State private var loaded: Bool = false

    var body: some View {
        Group {
            if let offering {
                PaywallView(offering: offering)
                    .onPurchaseCompleted { _ in onPurchased() }
                    .onRestoreCompleted { _ in onRestored() }
            } else if loaded {
                // Fallback: use the default current offering.
                PaywallView()
                    .onPurchaseCompleted { _ in onPurchased() }
                    .onRestoreCompleted { _ in onRestored() }
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
            offering = offerings.offering(identifier: context.rawValue)
        } catch {
            offering = nil
        }
        loaded = true
    }
}
