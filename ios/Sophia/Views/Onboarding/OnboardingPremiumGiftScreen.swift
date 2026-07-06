import SwiftUI

struct OnboardingPremiumGiftScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var badgeAppeared = false
    @State private var giftAppeared = false
    @State private var titleAppeared = false
    @State private var buttonAppeared = false
    @State private var giftBounce = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            BrutalPill(
                text: languageManager.text("onboarding.premiumGift.badge"),
                icon: "gift.fill",
                background: BrutalPalette.pink,
                foreground: BrutalPalette.ink
            )
            .opacity(badgeAppeared ? 1 : 0)
            .offset(y: badgeAppeared ? 0 : -12)

            Spacer().frame(height: 32)

            giftCard
                .opacity(giftAppeared ? 1 : 0)
                .scaleEffect(giftAppeared ? 1 : 0.9)

            Spacer().frame(height: 32)

            Text(languageManager.text("onboarding.premiumGift.title"))
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : 16)

            Spacer()

            OnboardingPrimaryButton(title: languageManager.text("common.continue"), action: onNext)
                .opacity(buttonAppeared ? 1 : 0)
                .offset(y: buttonAppeared ? 0 : 24)
        }
        .onboardingFullBleedBackground(BrutalPalette.cream)
        .onOnboardingSlideSettled {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                badgeAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.12)) {
                giftAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.28)) {
                titleAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.48)) {
                buttonAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                giftBounce += 1
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    @ViewBuilder
    private var giftCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(BrutalPalette.ink)
                .offset(y: 6)
                .frame(width: 148, height: 148)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(OnboardingPastels.at(0))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                }
                .frame(width: 148, height: 148)

            Image(systemName: "gift.fill")
                .font(.system(size: 64, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .symbolEffect(.bounce, value: giftBounce)
        }
        .padding(.bottom, 6)
    }
}
