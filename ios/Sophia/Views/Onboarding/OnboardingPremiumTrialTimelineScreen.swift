import SwiftUI

struct OnboardingPremiumTrialTimelineScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onUnlockTrial: () -> Void

    @State private var badgeAppeared = false
    @State private var iconAppeared = false
    @State private var titleAppeared = false
    @State private var footerAppeared = false
    @State private var buttonAppeared = false

    @State private var bellSwing = false
    @State private var ringPulse = false
    @State private var dotPop = false

    private let ink = BrutalPalette.ink
    private let pink = BrutalPalette.pink

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            BrutalPill(
                text: languageManager.text("onboarding.premiumTrial.badge"),
                icon: "sparkles",
                background: pink,
                foreground: ink
            )
            .opacity(badgeAppeared ? 1 : 0)
            .offset(y: badgeAppeared ? 0 : -10)

            notificationIcon
                .opacity(iconAppeared ? 1 : 0)
                .scaleEffect(iconAppeared ? 1 : 0.82)

            Text(languageManager.text("onboarding.trial.notifyTitle"))
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 30)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : 16)

            Text(languageManager.text("onboarding.premiumTrial.cancelAnytime"))
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink.opacity(0.5))
                .tracking(0.3)
                .opacity(footerAppeared ? 1 : 0)

            Spacer()

            OnboardingPrimaryButton(
                title: languageManager.text("onboarding.premiumTrial.cta"),
                action: onUnlockTrial
            )
            .opacity(buttonAppeared ? 1 : 0)
            .offset(y: buttonAppeared ? 0 : 24)
        }
        .onboardingFullBleedBackground(BrutalPalette.cream)
        .onOnboardingSlideSettled {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) {
                badgeAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.1)) {
                iconAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.26)) {
                titleAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.42)) {
                footerAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.54)) {
                buttonAppeared = true
            }
            startBellAnimations()
        }
    }

    private var notificationIcon: some View {
        ZStack {
            // Expanding pulse rings behind the badge.
            ForEach(0..<2, id: \.self) { i in
                Circle()
                    .strokeBorder(pink.opacity(0.45), lineWidth: 3)
                    .frame(width: 108, height: 108)
                    .scaleEffect(ringPulse ? 1.55 : 0.9)
                    .opacity(ringPulse ? 0 : 0.7)
                    .animation(
                        .easeOut(duration: 1.8)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.9),
                        value: ringPulse
                    )
            }

            // Brutalist badge with the bell.
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(ink)
                    .offset(y: 5)
                    .frame(width: 100, height: 100)

                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(OnboardingPastels.at(1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(ink, lineWidth: 2.5)
                    }
                    .frame(width: 100, height: 100)

                Image(systemName: "bell.fill")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(ink)
                    .rotationEffect(.degrees(bellSwing ? 11 : -11), anchor: .top)
                    .animation(
                        .easeInOut(duration: 0.55).repeatForever(autoreverses: true),
                        value: bellSwing
                    )
            }

            // Notification dot.
            Circle()
                .fill(Color(red: 0.95, green: 0.24, blue: 0.34))
                .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                .frame(width: 24, height: 24)
                .offset(x: 34, y: -34)
                .scaleEffect(dotPop ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.5), value: dotPop)
        }
        .frame(height: 128)
    }

    private func startBellAnimations() {
        bellSwing = true
        ringPulse = true
        dotPop = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
