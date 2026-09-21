import SwiftUI

/// Page 1 — Welcome to Sophia. Logo + animation d'ouverture douce, CTA « Get started ».
struct OnboardingV2Welcome: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void
    /// Tapped by someone who is reinstalling or switching phone. Optional so the
    /// screen still renders in a preview that has no coordinator behind it.
    var onExistingAccount: (() -> Void)? = nil

    @State private var logoIn = false
    @State private var haloScale: CGFloat = 0.6
    @State private var titleIn = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(OV2.accentSoft.opacity(0.10))
                    .frame(width: 220, height: 220)
                    .scaleEffect(haloScale)
                    .opacity(logoIn ? 1 : 0)

                Circle()
                    .fill(OV2.accentSoft.opacity(0.12))
                    .frame(width: 140, height: 140)
                    .scaleEffect(haloScale)
                    .opacity(logoIn ? 1 : 0)

                logo
                    .scaleEffect(logoIn ? 1 : 0.7)
                    .opacity(logoIn ? 1 : 0)
            }

            Spacer().frame(height: 40)

            VStack(spacing: 12) {
                Text(languageManager.text("onboardingV2.welcome.title"))
                    .font(DS.title(.largeTitle, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)

                Text(languageManager.text("onboardingV2.welcome.subtitle"))
                    .font(DS.sans(.body, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(titleIn ? 1 : 0)
            .offset(y: titleIn ? 0 : 16)

            Spacer()

            // No spacing of its own: `OnboardingV2Button` already carries 20pt below
            // itself, which is the gap between the two.
            VStack(spacing: 0) {
                OnboardingV2Button(title: languageManager.text("onboardingV2.welcome.cta"), action: onNext)

                // Quiet on purpose: this is the door for people who already know the
                // app, and it must not compete with "Get started" for a new one.
                if let onExistingAccount {
                    Button(action: onExistingAccount) {
                        Text(languageManager.text("onboardingV2.welcome.existingAccount"))
                            .font(DS.sans(.subheadline, .semibold))
                            .foregroundStyle(OV2.inkSecondary)
                            .underline()
                    }
                    .padding(.bottom, 24)
                    .opacity(titleIn ? 1 : 0)
                }
            }
        }
        .ov2Background()
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.7)) {
                logoIn = true
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                haloScale = 1.05
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.35)) {
                titleIn = true
            }
        }
    }

    @ViewBuilder
    private var logo: some View {
        if UIImage(named: "SplashLogo") != nil {
            Image("SplashLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 104, height: 104)
        } else {
            ZStack {
                Circle().fill(OV2.accent).frame(width: 104, height: 104)
                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}
