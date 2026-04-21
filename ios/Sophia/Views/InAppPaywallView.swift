import SwiftUI
import RevenueCat

struct InAppPaywallView: View {
    let store: StoreViewModel
    let onSubscribed: () -> Void
    let onDismiss: () -> Void
    @State private var selectedPlan: PlanType = .annual
    @State private var appeared: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false

    private enum PlanType {
        case monthly, annual
    }

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    SophiaTheme.background, SophiaTheme.background, SophiaTheme.background,
                    SophiaTheme.emerald.opacity(0.06), SophiaTheme.accent.opacity(0.04), SophiaTheme.emerald.opacity(0.06),
                    SophiaTheme.background, SophiaTheme.background, SophiaTheme.background
                ]
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        triggerHaptic(.light)
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.08), in: .circle)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(SophiaTheme.emerald.opacity(0.1))
                                    .frame(width: 90, height: 90)
                                Image("logo_white")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 36)
                            }
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.3)

                            Text("Débloque ton essai gratuit de Sophia Premium")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .opacity(appeared ? 1 : 0)

                            Text("Pour continuer, débloquez simplement\nvotre essai gratuit sans engagement")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .opacity(appeared ? 1 : 0)
                        }
                        .padding(.top, 8)

                        VStack(spacing: 10) {
                            InAppFeatureRow(icon: "infinity", text: "Cours et quiz illimités")
                            InAppFeatureRow(icon: "sparkles", text: "Nouveau contenu chaque semaine")
                            InAppFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Suivi de progression complet")
                        }
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                        VStack(spacing: 12) {
                            InAppPlanCard(
                                title: "Annuel",
                                priceMain: "39,99 \u{20AC}/an",
                                priceDetail: "soit 3,33 \u{20AC}/mois",
                                badge: "POPULAIRE",
                                originalPrice: "69,99 \u{20AC}",
                                savings: "-43%",
                                isSelected: selectedPlan == .annual,
                                onTap: {
                                    triggerHaptic(.light)
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedPlan = .annual
                                    }
                                }
                            )

                            InAppPlanCard(
                                title: "Mensuel",
                                priceMain: "9,99 \u{20AC}/mois",
                                priceDetail: "",
                                badge: nil,
                                originalPrice: nil,
                                savings: nil,
                                isSelected: selectedPlan == .monthly,
                                onTap: {
                                    triggerHaptic(.light)
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedPlan = .monthly
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                    }
                }

                VStack(spacing: 10) {
                    Button {
                        triggerHaptic(.medium)
                        Task {
                            let pkg = selectedPlan == .annual ? store.annualPackage : store.monthlyPackage
                            guard let pkg else { return }
                            let success = await store.purchase(package: pkg)
                            if success { onSubscribed() }
                        }
                    } label: {
                        Text("Commencer l'essai gratuit de 3 jours")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(SophiaTheme.emerald, in: .rect(cornerRadius: 16))
                    }
                    .disabled(store.isPurchasing)
                    .opacity(store.isPurchasing ? 0.6 : 1)
                    .padding(.horizontal, 24)

                    Text("Sans engagement")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))

                    Button {
                        Task { await store.restore() }
                    } label: {
                        Text("Restaurer les achats")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                    }

                    HStack(spacing: 12) {
                        Button {
                            showTerms = true
                        } label: {
                            Text("Conditions générales")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                        Text("·")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.2))
                        Button {
                            showPrivacy = true
                        } label: {
                            Text("Politique de confidentialité")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                    }
                }
                .padding(.bottom, 36)
            }

            if store.isPurchasing {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        g.impactOccurred()
    }
}

private struct InAppFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SophiaTheme.emerald)
                .frame(width: 30, height: 30)
                .background(SophiaTheme.emerald.opacity(0.12), in: .circle)
            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
    }
}

private struct InAppPlanCard: View {
    let title: String
    let priceMain: String
    let priceDetail: String
    let badge: String?
    let originalPrice: String?
    let savings: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                if let badge {
                    Text(badge)
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(SophiaTheme.emerald, in: .capsule)
                        .padding(.top, -10)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                            if let savings {
                                Text(savings)
                                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                                    .foregroundStyle(SophiaTheme.emerald)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(SophiaTheme.emerald.opacity(0.15), in: .capsule)
                            }
                        }
                        Text(priceDetail)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if let originalPrice {
                            Text(originalPrice)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.white.opacity(0.35))
                                .strikethrough(color: .white.opacity(0.35))
                        }
                        Text(priceMain)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, badge != nil ? 14 : 18)
            }
            .background(
                isSelected ? SophiaTheme.emerald.opacity(0.08) : .white.opacity(0.04),
                in: .rect(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? SophiaTheme.emerald.opacity(0.5) : .white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}
