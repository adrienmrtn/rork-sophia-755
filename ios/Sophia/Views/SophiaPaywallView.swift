import SwiftUI
import RevenueCat
import RevenueCatUI

/// Identifiers for each offering configured in the RevenueCat dashboard.
/// Each one mirrors the same underlying products but can be styled / worded
/// differently from the RC dashboard without redeploying.
enum SophiaPaywallContext: String, Identifiable {
    case finOnboarding = "fin_onboarding"
    case offreDiscount = "offre_discount"
    case debloquerCours = "debloquer_cours"

    var id: String { rawValue }

    /// RC offering used when a context-specific paywall cannot be resolved.
    static let fallbackOfferingIdentifier = finOnboarding.rawValue
}

/// Wrapper around `RevenueCatUI.PaywallView` that loads a specific offering by
/// identifier and falls back to the `fin_onboarding` RC paywall when it can't be found
/// or has no active paywall template — e.g. while offerings are still loading,
/// if the dashboard paywall is inactive, or if the offering hasn't been configured yet.
struct SophiaPaywallView: View {
    @Environment(\.dismiss) private var dismiss

    let context: SophiaPaywallContext
    /// When set, skips the async offerings fetch (e.g. onboarding prefetch).
    var preloadedOffering: Offering? = nil
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    @State private var offering: Offering?
    @State private var loaded: Bool = false
    @State private var presentedAt: Date?
    @State private var didTrackDismiss = false

    @ViewBuilder
    private func configuredPaywall(offering: Offering) -> some View {
        let paywall = PaywallView(offering: offering)
            .onPurchaseCompleted { _ in onPurchased() }
            .onRestoreCompleted { _ in onRestored() }

        paywall.onRequestedDismissal {
            trackDismissIfNeeded()
            dismiss()
            onDismissed?()
        }
    }

    var body: some View {
        Group {
            if let offering {
                configuredPaywall(offering: offering)
            } else if loaded {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text("Unable to load paywall")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Button("Retry") {
                            loaded = false
                            Task { await resolveOffering() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView().tint(.white)
                }
                .task(id: preloadedOffering?.identifier) {
                    if let preloadedOffering {
                        offering = preloadedOffering
                        loaded = true
                    } else {
                        await resolveOffering()
                    }
                }
            }
        }
        .onAppear {
            presentedAt = Date()
            didTrackDismiss = false
            AnalyticsService.trackPaywallViewed(context: context.rawValue)
        }
        .onDisappear {
            trackDismissIfNeeded()
        }
    }

    private func trackDismissIfNeeded() {
        guard !didTrackDismiss else { return }
        didTrackDismiss = true
        let duration = Int(Date().timeIntervalSince(presentedAt ?? Date()))
        AnalyticsService.trackPaywallDismissed(context: context.rawValue, durationSeconds: max(0, duration))
    }

    /// Loads an offering with an active RC paywall template for the given context.
    static func loadOffering(for context: SophiaPaywallContext) async -> Offering? {
        guard let offerings = try? await Purchases.shared.offerings() else { return nil }
        return resolveOffering(for: context.rawValue, in: offerings)
    }

    private func resolveOffering() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            let id = context.rawValue
            let resolved = Self.resolveOffering(for: id, in: offerings)
            #if DEBUG
            let available = offerings.all.values.map { "\($0.identifier)(paywall:\($0.hasPaywall))" }.joined(separator: ", ")
            print("[SophiaPaywall] looking for '\(id)' — available: [\(available)] — current: \(offerings.current?.identifier ?? "nil") — resolved: \(resolved?.identifier ?? "nil")")
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

    private static func offering(withIdentifier identifier: String, in offerings: Offerings) -> Offering? {
        if let offering = offerings.all[identifier] { return offering }
        if let offering = offerings.offering(identifier: identifier) { return offering }
        return offerings.all.values.first { $0.identifier == identifier }
    }

    /// Returns an offering only when RevenueCat has an active paywall template for it.
    /// Offerings without a paywall (inactive / unconfigured) must not be passed to
    /// `PaywallView(offering:)` — RC would silently show its generic default UI.
    private static func offeringWithPaywall(withIdentifier identifier: String, in offerings: Offerings) -> Offering? {
        guard let offering = offering(withIdentifier: identifier, in: offerings),
              offering.hasPaywall else {
            return nil
        }
        return offering
    }

    private static func resolveOffering(for contextIdentifier: String, in offerings: Offerings) -> Offering? {
        if let primary = offeringWithPaywall(withIdentifier: contextIdentifier, in: offerings) {
            return primary
        }

        #if DEBUG
        if let existing = offering(withIdentifier: contextIdentifier, in: offerings) {
            print("[SophiaPaywall] '\(contextIdentifier)' exists but has no active paywall (hasPaywall=\(existing.hasPaywall))")
        } else {
            print("[SophiaPaywall] '\(contextIdentifier)' not found in offerings")
        }
        #endif

        guard contextIdentifier != SophiaPaywallContext.fallbackOfferingIdentifier else { return nil }

        let fallbackId = SophiaPaywallContext.fallbackOfferingIdentifier
        if let fallback = offeringWithPaywall(withIdentifier: fallbackId, in: offerings) {
            #if DEBUG
            print("[SophiaPaywall] falling back to '\(fallbackId)'")
            #endif
            return fallback
        }

        if let current = offerings.current,
           current.hasPaywall,
           current.identifier != contextIdentifier {
            #if DEBUG
            print("[SophiaPaywall] falling back to current offering '\(current.identifier)'")
            #endif
            return current
        }

        return nil
    }
}
