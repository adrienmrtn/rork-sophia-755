import SwiftUI

struct OnboardingPremiumGiftScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var badgeAppeared = false
    @State private var giftAppeared = false
    @State private var titleAppeared = false
    @State private var perksAppeared = false
    @State private var buttonAppeared = false
    @State private var giftBounce = 0

    private var perks: [(icon: String, text: String, tint: Color)] {
        [
            ("book.fill", languageManager.text("onboarding.premiumGift.perk.courses"), OnboardingPastels.at(1)),
            ("checkmark.circle.fill", languageManager.text("onboarding.premiumGift.perk.quizzes"), OnboardingPastels.at(3)),
            ("sparkles", languageManager.text("onboarding.premiumGift.perk.allSubjects"), OnboardingPastels.at(4)),
        ]
    }

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

            Spacer().frame(height: 28)

            giftCard
                .opacity(giftAppeared ? 1 : 0)
                .scaleEffect(giftAppeared ? 1 : 0.9)

            Spacer().frame(height: 28)

            Text(languageManager.text("onboarding.premiumGift.title"))
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : 16)

            Spacer().frame(height: 24)

            VStack(spacing: 10) {
                ForEach(Array(perks.enumerated()), id: \.offset) { index, perk in
                    BrutalFeaturePill(icon: perk.icon, text: perk.text, tint: perk.tint)
                        .opacity(perksAppeared ? 1 : 0)
                        .offset(y: perksAppeared ? 0 : 12)
                        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(Double(index) * 0.08), value: perksAppeared)
                }
            }
            .padding(.horizontal, 24)

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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.45)) {
                perksAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.65)) {
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

private struct BrutalFeaturePill: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .frame(width: 28)

            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(BrutalPalette.ink, lineWidth: 2)
        }
        .brutalOffsetPlate(depth: 3, corner: 14)
    }
}
