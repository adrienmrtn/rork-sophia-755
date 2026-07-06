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

    private var steps: [(label: String, title: String, tint: Color, icon: String, highlighted: Bool)] {
        [
            (
                languageManager.text("onboarding.premiumTrial.step1.label"),
                languageManager.text("onboarding.premiumTrial.step1.title"),
                OnboardingPastels.at(3),
                "lock.open.fill",
                false
            ),
            (
                languageManager.text("onboarding.premiumTrial.step2.label"),
                languageManager.text("onboarding.premiumTrial.step2.title"),
                BrutalPalette.pink,
                "bell.fill",
                true
            ),
            (
                languageManager.text("onboarding.premiumTrial.step3.label"),
                languageManager.text("onboarding.premiumTrial.step3.title"),
                OnboardingPastels.at(0),
                "creditcard.fill",
                false
            ),
        ]
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            BrutalPill(
                text: languageManager.text("onboarding.premiumTrial.badge"),
                icon: "sparkles",
                background: BrutalPalette.pink,
                foreground: BrutalPalette.ink
            )
            .opacity(badgeAppeared ? 1 : 0)
            .offset(y: badgeAppeared ? 0 : -10)

            Text(languageManager.text("onboarding.premiumTrial.title"))
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : 18)

            timelineCard
                .padding(.horizontal, 24)
                .opacity(cardAppeared ? 1 : 0)
                .scaleEffect(cardAppeared ? 1 : 0.94)

            Text(languageManager.text("onboarding.premiumTrial.cancelAnytime"))
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink.opacity(0.5))
                .tracking(0.4)
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
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(BrutalPalette.ink)
                    .offset(y: 5)
                    .frame(width: 92, height: 92)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(OnboardingPastels.at(1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                    }
                    .frame(width: 92, height: 92)

                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .symbolEffect(.bounce, value: bellBounce)
            }

            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    PremiumTrialTimelineRow(
                        label: step.label,
                        title: step.title,
                        tint: step.tint,
                        icon: step.icon,
                        isHighlighted: step.highlighted,
                        isLast: index == steps.count - 1
                    )
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
    }
}

private struct PremiumTrialTimelineRow: View {
    let label: String
    let title: String
    let tint: Color
    var icon: String = "checkmark"
    var isHighlighted: Bool = false
    var isLast: Bool = false

    private let nodeSize: CGFloat = 38

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Connected node column
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(BrutalPalette.ink)
                        .offset(y: 3)
                        .frame(width: nodeSize, height: nodeSize)

                    Circle()
                        .fill(isHighlighted ? BrutalPalette.pink : tint)
                        .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2.5) }
                        .frame(width: nodeSize, height: nodeSize)

                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                }

                if !isLast {
                    Capsule()
                        .fill(BrutalPalette.ink.opacity(0.22))
                        .frame(width: 3)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 5)
                }
            }
            .frame(width: nodeSize)

            // Step content
            VStack(alignment: .leading, spacing: 7) {
                Text(label)
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(BrutalPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(tint, in: .capsule)
                    .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2) }
                    .fixedSize(horizontal: true, vertical: false)

                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: isHighlighted ? .heavy : .semibold))
                    .foregroundStyle(BrutalPalette.ink.opacity(isHighlighted ? 1 : 0.78))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 3)
            .padding(.bottom, isLast ? 0 : 22)
        }
    }
}
