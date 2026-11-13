import SwiftUI

/// Native paywall for the `audio` context: a free user tapped "Écouter", "Ajouter à la
/// file" or "Télécharger". Design « Elevate arrondi » : sans audio / avec l'audio en en-tête,
/// un lecteur d'exemple (la couverture et le titre du cours qu'on voulait écouter quand il y
/// en a un), les quatre atouts de l'écoute, puis le choix de formule.
///
/// Like every context paywall, it sells the offering RevenueCat currently serves (price
/// experiments apply), with an `audio` offering as fallback; the impression and the purchase
/// report that same offering (see `ElevatePaywallScreen`).
struct SophiaAudioPaywall: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let store: StoreViewModel
    var course: Course? = nil
    /// Off for the developer section, so looking at the screen is not a funnel event.
    var tracksAnalytics: Bool = true
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    private let context = SophiaPaywallContext.audio

    var body: some View {
        ElevatePaywallScreen(
            store: store,
            offeringIdentifier: context.offeringIdentifier,
            paywallId: "native_audio",
            tracksAnalytics: tracksAnalytics,
            layout: .bonhomme,
            onPurchased: onPurchased,
            onRestored: onRestored,
            onClose: {
                dismiss()
                onDismissed?()
            }
        ) {
            ElevateBeforeAfterHero(
                beforeImage: "pw_audio_before",
                afterImage: "pw_audio_after",
                beforeLabel: languageManager.text("paywall.elevate.audio.without"),
                afterLabel: languageManager.text("paywall.elevate.audio.with")
            )
            ElevatePaywallTitle(text: languageManager.text("paywall.elevate.audio.title"))
                .dsStagger(0)
            ElevatePaywallSubtitle(text: languageManager.text("paywall.audio.subtitle"))
                .dsStagger(1)
            ElevateSamplePlayerCard(course: course)
                .dsStagger(2)
            features
                .dsStagger(3)
        }
    }

    // MARK: Features

    private var features: some View {
        VStack(spacing: 0) {
            featureRow(icon: "lock.iphone", number: 1)
            rowDivider
            featureRow(icon: "globe", number: 2)
            rowDivider
            featureRow(icon: "speedometer", number: 3)
            rowDivider
            featureRow(icon: "arrow.down.to.line", number: 4)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .dsOptionCard(.idle)
        .padding(.horizontal, 20)
        .padding(.top, 28)
    }

    private var rowDivider: some View {
        Rectangle().fill(DS.hairline).frame(height: 1)
    }

    private func featureRow(icon: String, number: Int) -> some View {
        ElevateInfoRow(
            systemImage: icon,
            title: languageManager.text("paywall.elevate.audio.feature\(number).title"),
            detail: languageManager.text("paywall.elevate.audio.feature\(number).body"),
            alignment: .center
        )
        .padding(.vertical, 12)
    }
}
