import SwiftUI

// MARK: - Apps grisées, cadenas

/// Des tuiles d'apps de réseaux sociaux, grisées, un cadenas en haut à droite : l'image de
/// l'anti-scroll. Pas de logos de marques, des pictos qui évoquent chaque app.
struct AntiScrollLockedApps: View {
    var tileSize: CGFloat = 56
    var spacing: CGFloat = 12

    @State private var shown = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Dans l'ordre : une app de vidéos courtes, de photos, de vidéos, de messages, un réseau.
    private static let symbols = ["music.note", "camera.fill", "play.rectangle.fill", "bubble.left.fill", "at"]

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(Self.symbols.enumerated()), id: \.offset) { i, symbol in
                tile(symbol)
                    .scaleEffect(shown > i ? 1 : 0.6)
                    .opacity(shown > i ? 1 : 0)
            }
        }
        .accessibilityHidden(true)
        .onAppear { reveal() }
    }

    private func tile(_ symbol: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: tileSize * 0.28, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color(white: 0.82), Color(white: 0.66)], startPoint: .top, endPoint: .bottom)
                )
            Image(systemName: symbol)
                .font(.system(size: tileSize * 0.42, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(width: tileSize, height: tileSize)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "lock.fill")
                .font(.system(size: tileSize * 0.2, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: tileSize * 0.4, height: tileSize * 0.4)
                .background(DS.ink, in: Circle())
                .overlay(Circle().strokeBorder(DS.canvas, lineWidth: 2))
                .offset(x: tileSize * 0.14, y: -tileSize * 0.14)
        }
    }

    private func reveal() {
        guard shown == 0 else { return }
        if reduceMotion {
            shown = Self.symbols.count
            return
        }
        for i in 0..<Self.symbols.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(i) * 0.08) {
                withAnimation(DS.Motion.pop) { shown = i + 1 }
            }
        }
    }
}

// MARK: - Premier écran : « Active l'anti-scroll »

/// La feuille qui précède l'activation : le deal en une phrase, les apps grisées sous
/// cadenas, un bouton. Sans barre de titre ; on la tire vers le bas pour la fermer.
struct AntiScrollIntroSheet: View {
    @Environment(LanguageManager.self) private var languageManager
    let onActivate: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 30)

            DSHighlightTitle(text: languageManager.text("antiScroll.title"), style: .title2, weight: .medium)
                .padding(.horizontal, 28)

            Spacer(minLength: 26)

            AntiScrollLockedApps(tileSize: 56, spacing: 12)

            Spacer(minLength: 30)

            // La vibration du CTA vient du style du bouton.
            Button {
                onActivate()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "iphone.slash")
                        .font(.system(size: 15, weight: .bold))
                    Text(languageManager.text("antiScroll.cta"))
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 22)
        }
        .frame(maxWidth: OV2.readableWidth)
        .frame(maxWidth: .infinity)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .presentationBackground(DS.canvas)
    }
}

// MARK: - Paywall du blocker (contexte `blocker`)

/// Native paywall for the `blocker` context: a free reader asked to turn the anti-scroll on.
/// Design « Elevate arrondi » : sans / avec l'anti-scroll en en-tête, « Comment ça marche » en
/// trois étapes (avec les apps verrouillées de l'app), puis le choix de formule. It sells the
/// offering RevenueCat currently serves (price experiments included), see `ElevatePaywallScreen`.
struct SophiaBlockerPaywall: View {
    @Environment(LanguageManager.self) private var languageManager

    let store: StoreViewModel
    /// Off for the developer shortcut in Settings: the RevenueCat impression would otherwise
    /// count a paywall opened only to look at it.
    var tracksAnalytics: Bool = true
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    private let context = SophiaPaywallContext.blocker

    var body: some View {
        ElevatePaywallScreen(
            store: store,
            offeringIdentifier: context.offeringIdentifier,
            paywallId: "native_blocker",
            tracksAnalytics: tracksAnalytics,
            // La croix n'apparaît qu'au bout de 2 s, le temps de voir la valeur.
            closeDelay: 2,
            layout: .bonhomme,
            onPurchased: onPurchased,
            onRestored: onRestored,
            onClose: { onDismissed?() }
        ) {
            ElevateBeforeAfterHero(
                beforeImage: "pw_blocker_before",
                afterImage: "pw_blocker_after",
                beforeLabel: languageManager.text("paywall.elevate.blocker.without"),
                afterLabel: languageManager.text("paywall.elevate.blocker.with")
            )
            ElevatePaywallTitle(text: languageManager.text("paywall.elevate.blocker.title"))
                .dsStagger(0)
            ElevatePaywallSubtitle(text: languageManager.text("paywall.elevate.blocker.subtitle"))
                .dsStagger(1)
            ElevateBlockerStepsCard()
                .dsStagger(2)
        }
    }
}
