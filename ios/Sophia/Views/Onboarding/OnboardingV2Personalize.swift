import SwiftUI

/// Moment doux inséré juste avant le swipe de cours : la phrase « Personnalisons ton contenu »
/// se met en gras progressivement (mot par mot), exactement comme l'écran « Transforme ce
/// temps ». Chaque mot occupe un emplacement de largeur fixe (largeur « gras ») pour éviter tout
/// décalage du texte quand le gras arrive. Pas de CTA : on tape n'importe où pour ouvrir l'écran
/// « Des cours faits pour toi ».
///
/// Style « Elevate arrondi » : une illustration ronde au-dessus de la phrase, en très grand et
/// centrée ; l'invitation à toucher l'écran en bas.
struct OnboardingV2Personalize: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var boldCount = 0
    @State private var showHint = false
    @State private var advanced = false
    @State private var animTask: Task<Void, Never>?

    private var words: [String] {
        TextSegmentation.animationWords(languageManager.text("onboardingV2.personalize.text"))
    }

    var body: some View {
        GeometryReader { geo in
            let style: Font.TextStyle = OV2CoreMetrics.sentenceStyle(
                words: words,
                width: geo.size.width - OV2CoreMetrics.sideInset * 2
            )
            ZStack {
                VStack(spacing: 26) {
                    OV2CoreIllustration(art: .mirror, size: 160)
                        .dsPopIn(delay: 0.1)

                    OV2FlowLayout(spacing: languageManager.current == .japanese ? 0 : 8, lineSpacing: 6) {
                        ForEach(Array(words.enumerated()), id: \.offset) { i, word in
                            wordCell(word, bold: i < boldCount, style: style)
                        }
                    }
                }
                .padding(.horizontal, OV2CoreMetrics.sideInset)

                VStack {
                    Spacer()
                    OV2CoreTapHint(text: languageManager.text("onboardingV2.personalize.tapHint"), visible: showHint)
                        .padding(.bottom, 28)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ov2Background()
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .onAppear { animate() }
        .onDisappear { animTask?.cancel() }
    }

    // MARK: - Cellule de mot (largeur fixe = largeur « gras »)

    private func wordCell(_ word: String, bold: Bool, style: Font.TextStyle) -> some View {
        ZStack {
            // Sizer invisible en gras : réserve toujours la largeur maximale du mot.
            Text(word).font(DS.title(style, .heavy)).opacity(0)
            Text(word)
                .font(DS.title(style, bold ? .heavy : .regular))
                .foregroundStyle(bold ? OV2.ink : OV2.inkTertiary)
                .animation(.easeOut(duration: 0.3), value: bold)
        }
        .fixedSize()
    }

    // MARK: - Animation

    /// Cette page n'a pas de bouton : la seule indication qu'il faut taper est `showHint`,
    /// révélée à la fin de l'animation. Annulée en cours (rotation / redimensionnement de
    /// fenêtre sur iPad, retour d'arrière-plan), l'ancienne version laissait une phrase à
    /// moitié en gras, sans indice et sans issue visible — et `guard animTask == nil`
    /// interdisait tout redémarrage. L'animation reprend maintenant où elle en était, et
    /// l'indice s'affiche quoi qu'il arrive.
    private func animate() {
        guard !showHint else { return }
        animTask?.cancel()
        animTask = Task { @MainActor in
            await playAnimation()
            // Terminée ou interrompue, l'utilisateur sait toujours qu'il peut avancer.
            withAnimation(.easeIn(duration: 0.5)) { showHint = true }
        }
    }

    /// Gras progressif, mot par mot, repris à l'état courant.
    private func playAnimation() async {
        let count = words.count
        guard count > 0, boldCount < count else { return }
        if boldCount == 0 {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        for i in (boldCount + 1)...count {
            if Task.isCancelled { return }
            withAnimation(.easeOut(duration: 0.3)) { boldCount = i }
            OnboardingHaptics.selection()
            try? await Task.sleep(nanoseconds: 320_000_000)
        }
    }

    private func advance() {
        guard !advanced else { return }
        advanced = true
        animTask?.cancel()
        onNext()
    }
}
