import SwiftUI

/// Native SwiftUI paywall shown at the end of onboarding (replaces the RC paywall).
///
/// Layout:
/// - Two selectable plan cards (monthly / yearly, with yearly highlighted as "Best value")
/// - "Continuer" primary CTA
/// - Tapping "Continuer" presents a sheet reminding about the trial-end notification
///   with a second "Continuer" button that triggers the actual RevenueCat purchase
///   (wired in step 2).
struct OnboardingNativePaywallView: View {
    enum Plan: String, CaseIterable, Identifiable {
        case yearly
        case monthly
        var id: String { rawValue }
    }

    let onPurchase: (Plan) -> Void
    let onRestore: () -> Void
    let onClose: () -> Void

    @State private var selectedPlan: Plan = .yearly
    @State private var showReminderSheet: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        header
                            .padding(.top, 64)

                        VStack(spacing: 14) {
                            planCard(.yearly)
                            planCard(.monthly)
                        }
                        .padding(.horizontal, 24)

                        trialPerks
                            .padding(.horizontal, 24)

                        restoreRow
                            .padding(.top, 4)
                            .padding(.bottom, 12)
                    }
                    .padding(.bottom, 12)
                }

                OnboardingPrimaryButton(title: "Continuer") {
                    showReminderSheet = true
                }
            }

            closeButton
                .padding(.top, 12)
                .padding(.trailing, 16)
        }
        .sheet(isPresented: $showReminderSheet) {
            ReminderSheet(
                onContinue: {
                    showReminderSheet = false
                    onPurchase(selectedPlan)
                }
            )
            .presentationDetents([.height(440)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            BrutalPill(
                text: "Essai gratuit · 3 jours",
                icon: "sparkles",
                background: BrutalPalette.pink,
                foreground: BrutalPalette.ink
            )

            Text("Débloque tout\nSophia gratuitement")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)

            Text("Choisis ton offre. Annulable à tout moment\npendant l'essai, sans frais.")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Plan card

    @ViewBuilder
    private func planCard(_ plan: Plan) -> some View {
        let isSelected = selectedPlan == plan
        let isYearly = plan == .yearly
        let tint: Color = isYearly ? OnboardingPastels.at(3) : OnboardingPastels.at(1)

        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedPlan = plan
            }
        } label: {
            HStack(spacing: 14) {
                // Radio
                ZStack {
                    Circle()
                        .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Circle()
                            .fill(BrutalPalette.ink)
                            .frame(width: 26, height: 26)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundStyle(.white)
                            }
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(isYearly ? "Annuel" : "Mensuel")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                        if isYearly {
                            BrutalPill(
                                text: "Économise 66 %",
                                background: BrutalPalette.ink,
                                foreground: .white
                            )
                        }
                    }
                    Text(isYearly
                         ? "3,33 € / mois · facturé annuellement"
                         : "Sans engagement")
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.6))
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(isYearly ? "39,99 €" : "9,99 €")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                    Text(isYearly ? "/ an" : "/ mois")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .buttonStyle(BrutalRowButtonStyle(isSelected: isSelected, accentColor: tint))
    }

    // MARK: - Trial perks

    private var trialPerks: some View {
        VStack(alignment: .leading, spacing: 12) {
            perkRow(icon: "checkmark.seal.fill", text: "Accès illimité à toutes les matières")
            perkRow(icon: "bolt.fill", text: "Nouveaux cours chaque semaine")
            perkRow(icon: "bell.fill", text: "Notif 1 jour avant la fin de l'essai")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .brutalOnboardingCard(depth: 3, corner: 18)
    }

    private func perkRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(BrutalPalette.pink.opacity(0.5))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(BrutalPalette.ink, lineWidth: 2)
                    }
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
            }
            .frame(width: 30, height: 30)

            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Restore

    private var restoreRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onRestore()
        } label: {
            Text("Restaurer les achats")
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                .underline()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Close

    private var closeButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onClose()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.black.opacity(0.45))
                .clipShape(Circle())
        }
        .accessibilityLabel("Fermer")
    }
}

// MARK: - Reminder sheet

private struct ReminderSheet: View {
    let onContinue: () -> Void
    @State private var iconBounce: Int = 0

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 8)

                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(BrutalPalette.ink)
                        .offset(y: 4)
                        .frame(width: 88, height: 88)
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(OnboardingPastels.at(1))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                        }
                        .frame(width: 88, height: 88)
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 38, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .symbolEffect(.bounce, value: iconBounce)
                }

                Text("Pas de surprise")
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)

                Text("Nous t'enverrons une notification\n1 jour avant la fin de ton essai gratuit\nde 3 jours, pour que tu puisses annuler\nsi tu le souhaites.")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)

                Spacer()

                OnboardingPrimaryButton(title: "Continuer", action: onContinue)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                iconBounce += 1
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }
}
