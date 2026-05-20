import SwiftUI

struct OnboardingFreeTrialTimelineView: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var iconBounce: Int = 0

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(SophiaTheme.emerald.opacity(0.12))
                            .frame(width: 110, height: 110)
                            .scaleEffect(appeared ? 1 : 0.5)

                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(SophiaTheme.emerald)
                            .symbolEffect(.bounce, value: iconBounce)
                    }
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 16) {
                        Text("Nous vous notifierons\n1 jour avant la fin\nde votre essai gratuit")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(SophiaTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)

                        Text("Annulez à tout moment, sans frais.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.5))
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                    }
                }

                Spacer()

                OnboardingButton(title: "Continuer", action: onNext)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.2)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                iconBounce += 1
                let g = UIImpactFeedbackGenerator(style: .medium)
                g.impactOccurred()
            }
        }
    }
}
