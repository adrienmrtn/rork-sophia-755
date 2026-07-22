import SwiftUI

// MARK: - Questions (« Me cultiver au quotidien »)

/// « Avec Sophia, tu sauras répondre à ces questions » — les questions défilent en douceur,
/// façon **roulette** : la question centrée est nette, celles du dessus et du dessous sont
/// visibles mais atténuées et floutées, et l'ensemble glisse lentement vers le haut.
/// Montré à tout le monde (page « me cultiver au quotidien »), quel que soit l'objectif choisi.
struct OnboardingV2QuestionsScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    /// Position continue de la roulette : s'incrémente de 1 à chaque tick, sans jamais
    /// « wrapper », pour que le glissement reste toujours fluide (le contenu, lui, boucle
    /// via un modulo sur la liste des questions).
    @State private var position: Double = 0
    @State private var appeared = false

    /// Espacement vertical entre deux questions de la roulette.
    private let slotSpacing: CGFloat = 104
    /// Ralenti d'~25 % par rapport à l'ancienne rotation (plus fluide, moins sec).
    private let scrollDuration: Double = 0.95
    private let tickInterval: UInt64 = 1_600_000_000

    private var questions: [String] {
        (1...10).map { languageManager.text("onboardingV2.questions.q\($0)") }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 84)

            Text(languageManager.text("onboardingV2.questions.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.1)

            Spacer()

            roulette
                .frame(height: 320)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
                .opacity(appeared ? 1 : 0)
                // Dégradé haut/bas pour renforcer l'effet « roulette » (les voisines
                // s'estompent en s'éloignant du centre).
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black, location: 0.28),
                            .init(color: .black, location: 0.72),
                            .init(color: .clear, location: 1.0),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        .task {
            // Rotation continue tant que l'écran est visible (glissement lent et fluide).
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: tickInterval)
                if Task.isCancelled { break }
                withAnimation(.easeInOut(duration: scrollDuration)) {
                    position += 1
                }
                OnboardingHaptics.selection()
            }
        }
    }

    // MARK: - Roulette

    private var roulette: some View {
        let count = max(questions.count, 1)
        // Fenêtre de slots visibles autour de la position courante (une au-dessus, une
        // au-dessous), chacune identifiée par son index absolu → identité stable pour un
        // glissement propre plutôt qu'un simple fondu.
        let base = Int(position.rounded(.down))
        let slots = Array((base - 1)...(base + 2))
        return ZStack {
            ForEach(slots, id: \.self) { k in
                let distance = Double(k) - position
                let qi = ((k % count) + count) % count
                questionCard(questions[qi], focused: abs(distance) < 0.5)
                    .scaleEffect(scale(for: distance))
                    .opacity(opacity(for: distance))
                    .blur(radius: blur(for: distance))
                    .offset(y: CGFloat(distance) * slotSpacing)
                    .zIndex(abs(distance) < 0.5 ? 1 : 0)
                    .transition(.opacity)
            }
        }
    }

    private func scale(for distance: Double) -> CGFloat {
        let d = min(abs(distance), 1)
        return 1 - 0.16 * CGFloat(d)
    }

    private func opacity(for distance: Double) -> Double {
        let d = abs(distance)
        if d < 0.5 { return 1 }
        return max(0, 0.42 - (d - 0.5) * 0.42)
    }

    private func blur(for distance: Double) -> CGFloat {
        let d = abs(distance)
        if d < 0.5 { return 0 }
        return min(7, CGFloat((d - 0.5) * 9))
    }

    private func questionCard(_ q: String, focused: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(OV2.accentSoft)
            Text(q)
                .font(DS.title(.title2, .bold))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OV2.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(OV2.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(focused ? 0.08 : 0.03), radius: focused ? 16 : 8, y: focused ? 8 : 4)
    }
}
