import SwiftUI

struct OnboardingPremiumTrialTimelineScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onUnlockTrial: () -> Void

    @State private var badgeAppeared = false
    @State private var titleAppeared = false
    @State private var cardAppeared = false
    @State private var footerAppeared = false
    @State private var buttonAppeared = false
    @State private var bellBounce = 0

    private var steps: [(label: String, title: String, tint: Color, highlighted: Bool)] {
        [
            (
                languageManager.text("onboarding.premiumTrial.step1.label"),
                languageManager.text("onboarding.premiumTrial.step1.title"),
                OnboardingPastels.at(3),
                false
            ),
            (
                languageManager.text("onboarding.premiumTrial.step2.label"),
                languageManager.text("onboarding.premiumTrial.step2.title"),
                BrutalPalette.pink,
                true
            ),
            (
                languageManager.text("onboarding.premiumTrial.step3.label"),
                languageManager.text("onboarding.premiumTrial.step3.title"),
                OnboardingPastels.at(0),
                false
            ),
        ]
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            BrutalPill(
                text: languageManager.text("onboarding.premiumTrial.badge"),
                icon: "bell.fill",
                background: BrutalPalette.pink,
                foreground: BrutalPalette.ink
            )
            .opacity(badgeAppeared ? 1 : 0)
            .offset(y: badgeAppeared ? 0 : -10)

            Text(languageManager.text("onboarding.premiumTrial.title"))
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : 18)

            timelineCard
                .padding(.horizontal, 24)
                .opacity(cardAppeared ? 1 : 0)
                .scaleEffect(cardAppeared ? 1 : 0.94)

            Text(languageManager.text("onboarding.premiumTrial.cancelAnytime"))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink.opacity(0.6))
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.12)) {
                titleAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.32)) {
                cardAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
                footerAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.62)) {
                buttonAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                bellBounce += 1
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }

    @ViewBuilder
    private var timelineCard: some View {
        VStack(spacing: 18) {
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
                    .symbolEffect(.bounce, value: bellBounce)
            }
            .padding(.top, 4)

            ZStack(alignment: .topLeading) {
                GeometryReader { geo in
                    let firstCenterY: CGFloat = 24
                    let lastCenterY = geo.size.height - 24
                    let lineX: CGFloat = 4

                    Path { path in
                        path.move(to: CGPoint(x: lineX, y: firstCenterY))
                        path.addLine(to: CGPoint(x: lineX, y: lastCenterY))
                    }
                    .stroke(BrutalPalette.ink.opacity(0.15), lineWidth: 2)
                }

                VStack(spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        PremiumTrialTimelineRow(
                            label: step.label,
                            title: step.title,
                            tint: step.tint,
                            isHighlighted: step.highlighted
                        )
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .brutalOnboardingCard(depth: 4, corner: 22)
    }
}

private struct PremiumTrialTimelineRow: View {
    let label: String
    let title: String
    let tint: Color
    var isHighlighted: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(isHighlighted ? BrutalPalette.pink : BrutalPalette.ink.opacity(0.12))
                .frame(width: 10, height: 10)
                .overlay {
                    Circle().strokeBorder(BrutalPalette.ink.opacity(isHighlighted ? 1 : 0.25), lineWidth: 1.5)
                }
                .padding(.top, 19)
                .frame(width: 10)

            HStack(alignment: .top, spacing: 12) {
                Text(label)
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .tracking(0.6)
                    .foregroundStyle(BrutalPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(tint, in: .capsule)
                    .overlay {
                        Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2)
                    }
                    .fixedSize(horizontal: true, vertical: false)

                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: isHighlighted ? .heavy : .semibold))
                    .foregroundStyle(BrutalPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isHighlighted {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 10)
        }
    }
}
