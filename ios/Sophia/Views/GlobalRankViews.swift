import SwiftUI

/// Le passage à un nouveau rang global, dans le style « Elevate arrondi » : le nouveau rang dans
/// sa carte bordée, l'ancien et le nouveau côte à côte, puis « Continuer ».
struct GlobalRankUpCelebrationView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)

                    Text(String(format: languageManager.text("globalRank.reachedLevel"), newLevel))
                        .font(DS.sans(.subheadline))
                        .foregroundStyle(DS.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                        .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 26)

                    rankCard
                        .scaleEffect(cardScale)
                        .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 26)

                    HStack(spacing: 10) {
                        rankChip(previousRank, faded: true)
                        Image(systemName: "arrow.forward")
                            .font(.jakarta(size: 15, weight: .medium))
                            .foregroundStyle(DS.inkTertiary)
                        rankChip(newRank, faded: false)
                    }
                    .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 28)

                    // Le CTA vibre de lui-même (`DSPrimaryButtonStyle`).
                    Button {
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
        .sophiaColorScheme()
    }

    private var rankCard: some View {
        VStack(spacing: 18) {
            GlobalRankAnimatedIcon(rank: newRank, size: 116)
                .scaleEffect(iconScale)

            Text(newRank.localizedName(language: languageManager.current))
                .font(DS.title(.title, .bold))
                .foregroundStyle(DS.accent)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            DSChip(text: languageManager.text("globalRank.badge"))
        }
        .padding(.vertical, 32)
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1.5)
        }
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(DS.hairline)
                .offset(y: 1.5)
        )
    }

    private func rankChip(_ rank: GlobalRank, faded: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: rank.symbolName)
                .font(.jakarta(size: 12, weight: .medium))
            Text(rank.localizedName(language: languageManager.current))
                .font(DS.sans(.caption, faded ? .medium : .bold))
        }
        .foregroundStyle(faded ? DS.inkTertiary : DS.accent)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(faded ? DS.surface : DS.accentTint)
        )
        .overlay(
            Capsule().strokeBorder(faded ? DS.hairline : Color.clear, lineWidth: 1.5)
        )
    }

    private func runSequence() {
        if reduceMotion {
            appeared = true
            cardScale = 1
            iconScale = 1
            Haptics.celebrate()
            return
        }
        withAnimation(DS.Motion.reveal) {
            appeared = true
            cardScale = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            // La récompense : le badge du rang se pose avec son rebond.
            Haptics.celebrate()
            withAnimation(DS.Motion.pop) {
                iconScale = 1
            }
        }
    }
}

/// Le badge animé d'un rang : un disque en dégradé aux couleurs du rang (porteuses de sens),
/// son symbole, et un halo qui respire doucement. Immobile quand « Réduire les animations »
/// est actif.
struct GlobalRankAnimatedIcon: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let rank: GlobalRank
    var size: CGFloat

    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(rank.primaryColor.opacity(pulse ? 0.22 : 0.12))
                .frame(width: size * 1.16, height: size * 1.16)
                .scaleEffect(pulse ? 1.04 : 0.96)

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
                .font(.jakarta(size: size * 0.4, weight: .medium))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
