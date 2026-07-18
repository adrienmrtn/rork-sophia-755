import SwiftUI

struct GlobalRankUpCelebrationView: View {
    @Environment(LanguageManager.self) private var languageManager
    let previousRank: GlobalRank
    let newRank: GlobalRank
    let newLevel: Int
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var cardScale: CGFloat = 0.8
    @State private var iconScale: CGFloat = 0.5

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 24)

                    Text(languageManager.text("globalRank.newRank"))
                        .font(DS.title(.title, .semibold))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)

                    Text(String(format: languageManager.text("globalRank.reachedLevel"), newLevel))
                        .font(DS.sans(.subheadline))
                        .foregroundStyle(DS.inkSecondary)
                        .padding(.top, 6)
                        .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 26)

                    rankCard
                        .scaleEffect(cardScale)
                        .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 26)

                    HStack(spacing: 10) {
                        rankChip(previousRank, faded: true)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(DS.inkTertiary)
                        rankChip(newRank, faded: false)
                    }
                    .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 28)

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onContinue()
                    } label: {
                        Text(languageManager.text("common.continue"))
                    }
                    .buttonStyle(DSPrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear { runSequence() }
    }

    private var rankCard: some View {
        VStack(spacing: 18) {
            GlobalRankAnimatedIcon(rank: newRank, size: 116)
                .scaleEffect(iconScale)

            Text(newRank.localizedName(language: languageManager.current))
                .font(DS.title(.title, .semibold))
                .foregroundStyle(DS.ink)

            Text(languageManager.text("globalRank.badge"))
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(DS.accentSoft)
                .tracking(1.0)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(DS.accentTint, in: Capsule())
        }
        .padding(.vertical, 32)
        .frame(width: 260)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
    }

    private func rankChip(_ rank: GlobalRank, faded: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: rank.symbolName)
                .font(.system(size: 12, weight: .medium))
            Text(rank.localizedName(language: languageManager.current))
                .font(DS.sans(.caption, .medium))
        }
        .foregroundStyle(faded ? DS.inkTertiary : DS.accentSoft)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(faded ? DS.surfaceMuted : DS.accentTint, in: Capsule())
    }

    private func runSequence() {
        withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
            appeared = true
            cardScale = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                iconScale = 1
            }
        }
    }
}

/// Calm animated rank icon: a soft gradient circle with the rank symbol and a gentle
/// breathing glow — no orbiting sparkles or spinning rings.
struct GlobalRankAnimatedIcon: View {
    let rank: GlobalRank
    var size: CGFloat

    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(rank.primaryColor.opacity(pulse ? 0.5 : 0.28))
                .frame(width: size * 1.12, height: size * 1.12)
                .blur(radius: size * 0.12)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [rank.primaryColor, rank.secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: rank.symbolName)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
