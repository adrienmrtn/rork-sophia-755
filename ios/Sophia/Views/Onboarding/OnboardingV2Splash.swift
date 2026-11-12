import SwiftUI

/// Écran 0 — logo animé joué une fois à l'ouverture de l'onboarding, par-dessus la page
/// d'accueil : le symbole apparaît au centre en douceur, glisse à gauche, et le
/// mot « Sophia » se déroule à sa droite. Puis le voile se lève sur l'accueil.
///
/// L'écran de lancement du système (image `SplashLogo` centrée) ne s'anime pas : cette vue
/// prend sa suite, le symbole au même endroit, pour que les deux s'enchaînent.
struct OnboardingV2Splash: View {
    /// Appelé une seule fois, quand l'animation a fini de jouer.
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var markScale: CGFloat = 0.86
    @State private var markCentered = true
    @State private var wordShown = false
    @State private var wordReveal: CGFloat = 0
    @State private var didFinish = false

    /// Durée de l'animation avant que le voile commence à se lever.
    static let totalDuration: TimeInterval = 1.5

    /// Largeur du logo complet (symbole + mot), comme sur la maquette.
    private static let logoWidth: CGFloat = 212
    /// Proportions de l'image `sophia_mark` (1192 × 334).
    private static let logoAspect: CGFloat = 1192.0 / 334.0
    /// Part de la largeur occupée par le symbole, à gauche du mot.
    private static let markFraction: CGFloat = 0.247

    private var logoHeight: CGFloat { Self.logoWidth / Self.logoAspect }
    private var markWidth: CGFloat { Self.logoWidth * Self.markFraction }
    private var wordWidth: CGFloat { Self.logoWidth - markWidth }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            ZStack(alignment: .leading) {
                wordmark
                mark
            }
            .frame(width: Self.logoWidth, height: logoHeight)
            // Le logo est un dessin : il ne se retourne pas dans une langue de droite à gauche.
            .environment(\.layoutDirection, .leftToRight)
        }
        .contentShape(Rectangle())
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: "Sophia"))
        .task { await play() }
    }

    // MARK: - Calques

    private var logo: some View {
        Image("sophia_mark")
            .resizable()
            .scaledToFit()
            .frame(width: Self.logoWidth, height: logoHeight)
    }

    /// Le symbole seul : le logo masqué à sa partie gauche, d'abord centré dans le cadre.
    private var mark: some View {
        logo
            .mask(alignment: .leading) {
                Rectangle().frame(width: markWidth)
            }
            .scaleEffect(markScale, anchor: UnitPoint(x: Self.markFraction / 2, y: 0.5))
            .offset(x: markCentered ? wordWidth / 2 : 0)
    }

    /// Le mot : le logo masqué à sa partie droite, découvert de gauche à droite.
    private var wordmark: some View {
        logo
            .mask(alignment: .leading) {
                Rectangle()
                    .frame(width: wordWidth * wordReveal)
                    .offset(x: markWidth)
            }
            .offset(x: wordShown ? 0 : -18)
            .opacity(wordShown ? 1 : 0)
    }

    // MARK: - Animation

    private func play() async {
        guard !didFinish else { return }

        if reduceMotion {
            // Pas de mouvement : le logo complet, un court instant.
            markScale = 1
            markCentered = false
            wordShown = true
            wordReveal = 1
            await pause(0.7)
            finish()
            return
        }

        withAnimation(OV2CoreMotion.settle) {
            markScale = 1
        }
        await pause(0.55)

        withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
            markCentered = false
            wordShown = true
            wordReveal = 1
        }
        Haptics.soft()
        await pause(Self.totalDuration - 0.55)

        finish()
    }

    private func pause(_ seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }
}
