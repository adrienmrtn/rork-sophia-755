import SwiftUI

struct OnboardingFreeTrialTimelineView: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void
    @State private var appeared: Bool = true
    @State private var cardAppeared: Bool = false
    @State private var buttonAppeared: Bool = false
    @State private var iconBounce: Int = 0

    private var steps: [(day: String, title: String, tint: Color, highlighted: Bool)] {
        [
            (languageManager.text("onboarding.trial.day1"), languageManager.text("onboarding.trial.fullAccess"), OnboardingPastels.at(3), false),
            (languageManager.text("onboarding.trial.day2"), languageManager.text("onboarding.trial.notificationSent"), BrutalPalette.pink, true),
            (languageManager.text("onboarding.trial.day3"), languageManager.text("onboarding.trial.trialEnds"), OnboardingPastels.at(0), false),
        ]
    }

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                BrutalPill(text: languageManager.text("onboarding.trial.noSurprise"), icon: "bell.fill", background: BrutalPalette.pink, foreground: BrutalPalette.ink)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -10)

                Text(languageManager.text("onboarding.trial.notifyTitle"))
                    .font(.jakarta(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)

                timelineCard
                    .padding(.horizontal, 24)
                    .opacity(cardAppeared ? 1 : 0)
                    .scaleEffect(cardAppeared ? 1 : 0.94)

                Text(languageManager.text("onboarding.trial.cancelAnytime"))
                    .font(.jakarta(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.6))
                    .opacity(cardAppeared ? 1 : 0)

                Spacer()

                OnboardingPrimaryButton(title: languageManager.text("common.continue"), action: onNext)
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
                    .font(.jakarta(size: 42, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .symbolEffect(.bounce, value: iconBounce)
            }
            .padding(.top, 4)

            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    TimelineRow(
                        day: step.day,
                        title: step.title,
                        tint: step.tint,
                        isHighlighted: step.highlighted,
                        isFirst: index == 0,
                        isLast: index == steps.count - 1
                    )
                }
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
    var isFirst: Bool = false
    var isLast: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(BrutalPalette.ink.opacity(0.15))
                        .frame(width: 2, height: 10)
                } else {
                    Color.clear.frame(width: 2, height: 10)
                }

                Circle()
                    .fill(isHighlighted ? BrutalPalette.pink : BrutalPalette.ink.opacity(0.12))
                    .frame(width: 10, height: 10)
                    .overlay {
                        Circle().strokeBorder(BrutalPalette.ink.opacity(isHighlighted ? 1 : 0.25), lineWidth: 1.5)
                    }

                if !isLast {
                    Rectangle()
                        .fill(BrutalPalette.ink.opacity(0.15))
                        .frame(width: 2)
                        .frame(minHeight: 34)
                }
            }
            .frame(width: 10)
            .padding(.top, 14)

            HStack(spacing: 12) {
                Text(day)
                    .font(.jakarta(.caption, design: .rounded, weight: .heavy))
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
                    .font(.jakarta(.subheadline, design: .rounded, weight: isHighlighted ? .heavy : .semibold))
                    .foregroundStyle(BrutalPalette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isHighlighted {
                    Image(systemName: "bell.fill")
                        .font(.jakarta(size: 14, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                }
            }
            .padding(.vertical, 10)
        }
    }
}
