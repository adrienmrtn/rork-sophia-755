import SwiftUI

struct OnboardingFreeTrialTimelineView: View {
    let onNext: () -> Void
    @State private var appeared: Bool = true
    @State private var cardAppeared: Bool = false
    @State private var buttonAppeared: Bool = false
    @State private var iconBounce: Int = 0

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Pill badge
                BrutalPill(text: "Pas de surprise", icon: "bell.fill", background: BrutalPalette.pink, foreground: BrutalPalette.ink)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -10)

                // Title
                Text("Nous vous notifierons\n1 jour avant la fin\nde votre essai gratuit")
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)

                // Brutal card with icon + reassurance
                timelineCard
                    .padding(.horizontal, 24)
                    .opacity(cardAppeared ? 1 : 0)
                    .scaleEffect(cardAppeared ? 1 : 0.94)

                Text("Annulez à tout moment, sans frais.")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.6))
                    .opacity(cardAppeared ? 1 : 0)

                Spacer()

                OnboardingPrimaryButton(title: "Continuer", action: onNext)
                    .opacity(buttonAppeared ? 1 : 0)
                    .offset(y: buttonAppeared ? 0 : 24)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.15)) {
                appeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.45)) {
                cardAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.75)) {
                buttonAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                iconBounce += 1
                let g = UIImpactFeedbackGenerator(style: .medium)
                g.impactOccurred()
            }
        }
    }

    @ViewBuilder
    private var timelineCard: some View {
        VStack(spacing: 18) {
            // Big bell icon in a brutal square
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(BrutalPalette.ink)
                    .offset(y: 4)
                    .frame(width: 96, height: 96)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(OnboardingPastels.at(1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                    }
                    .frame(width: 96, height: 96)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .symbolEffect(.bounce, value: iconBounce)
            }
            .padding(.top, 4)

            // Mini timeline rows
            VStack(spacing: 12) {
                TimelineRow(day: "JOUR 1", title: "Accès complet", tint: OnboardingPastels.at(3))
                TimelineRow(day: "JOUR 2", title: "Notification envoyée", tint: BrutalPalette.pink, isHighlighted: true)
                TimelineRow(day: "JOUR 3", title: "Fin de l'essai", tint: OnboardingPastels.at(0))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .brutalOnboardingCard(depth: 4, corner: 22)
    }
}

private struct TimelineRow: View {
    let day: String
    let title: String
    let tint: Color
    var isHighlighted: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text(day)
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(BrutalPalette.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tint, in: .capsule)
                .overlay {
                    Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2)
                }
                .frame(width: 92, alignment: .leading)

            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: isHighlighted ? .heavy : .semibold))
                .foregroundStyle(BrutalPalette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isHighlighted {
                Image(systemName: "bell.fill")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
            }
        }
    }
}
