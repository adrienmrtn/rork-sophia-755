import SwiftUI

/// Moment doux inséré juste avant le swipe de cours : la phrase « Personnalisons ton contenu »
/// se met en gras progressivement (mot par mot), exactement comme l'écran « Transforme ce
/// temps ». Chaque mot occupe un emplacement de largeur fixe (largeur « gras ») pour éviter tout
/// décalage du texte quand le gras arrive. Pas de CTA : on tape n'importe où pour ouvrir l'écran
/// « Des cours faits pour toi ».
struct OnboardingV2Personalize: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var boldCount = 0
    @State private var showHint = false
    @State private var advanced = false
    @State private var animTask: Task<Void, Never>?

    private var words: [String] {
        languageManager.text("onboardingV2.personalize.text")
            .split(separator: " ")
            .map(String.init)
    }

    var body: some View {
        ZStack {
            OV2.bg.ignoresSafeArea()

            OV2FlowLayout(spacing: 7, lineSpacing: 10) {
                ForEach(Array(words.enumerated()), id: \.offset) { i, word in
                    wordCell(word, bold: i < boldCount)
                }
            }
            .padding(.horizontal, 28)

            VStack {
                Spacer()
                Text(languageManager.text("onboardingV2.personalize.tapHint"))
                    .font(DS.sans(.footnote, .semibold))
                    .foregroundStyle(OV2.inkTertiary)
                    .opacity(showHint ? 1 : 0)
                    .padding(.bottom, 40)
            }
        }
        .ov2Background()
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .onAppear { animate() }
        .onDisappear { animTask?.cancel() }
    }

    // MARK: - Cellule de mot (largeur fixe = largeur « gras »)

    private func wordCell(_ word: String, bold: Bool) -> some View {
        ZStack {
            // Sizer invisible en gras : réserve toujours la largeur maximale du mot.
            Text(word).font(DS.title(.title, .heavy)).opacity(0)
            Text(word)
                .font(DS.title(.title, bold ? .heavy : .regular))
                .foregroundStyle(bold ? OV2.ink : OV2.inkTertiary)
                .animation(.easeOut(duration: 0.3), value: bold)
        }
        .fixedSize()
    }

    // MARK: - Animation

    private func animate() {
        guard animTask == nil else { return }
        animTask = Task { @MainActor in
            let count = words.count
            guard count > 0 else { showHint = true; return }

            // Gras progressif, mot par mot.
            try? await Task.sleep(nanoseconds: 500_000_000)
            for i in 1...count {
                if Task.isCancelled { return }
                withAnimation(.easeOut(duration: 0.3)) { boldCount = i }
                OnboardingHaptics.selection()
                try? await Task.sleep(nanoseconds: 320_000_000)
            }

            if Task.isCancelled { return }
            withAnimation(.easeIn(duration: 0.5)) { showHint = true }
        }
    }

    private func advance() {
        guard !advanced else { return }
        advanced = true
        animTask?.cancel()
        onNext()
    }
}
