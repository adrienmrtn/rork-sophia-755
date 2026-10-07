import SwiftUI

// MARK: - Apps grisées, cadenas

/// Des tuiles d'apps de réseaux sociaux, grisées, un cadenas en haut à droite : l'image de
/// l'anti-scroll. Pas de logos de marques, des pictos qui évoquent chaque app.
struct AntiScrollLockedApps: View {
    var tileSize: CGFloat = 56
    var spacing: CGFloat = 12

    @State private var shown = 0

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
        for i in 0..<Self.symbols.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(i) * 0.08) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.65)) { shown = i + 1 }
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

            Text(languageManager.text("antiScroll.title"))
                .font(DS.title(.title2, .heavy))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)

            Spacer(minLength: 26)

            AntiScrollLockedApps(tileSize: 56, spacing: 12)

            Spacer(minLength: 30)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onActivate()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "iphone.slash")
                        .font(.jakarta(size: 15, weight: .bold))
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
        .presentationCornerRadius(30)
        .presentationBackground(DS.canvas)
    }
}

// MARK: - Paywall du blocker (contexte `blocker`)

/// Native paywall for the `blocker` context: a free reader asked to turn the anti-scroll on.
/// « Prends enfin le contrôle de ton temps avec le blocker », the trial days in green, the
/// locked apps, then what else PRO unlocks, and the usual price line and CTA. It sells the
/// annual plan of the offering RevenueCat currently serves (price experiments included).
struct SophiaBlockerPaywall: View {
    @Environment(LanguageManager.self) private var languageManager

    let store: StoreViewModel
    /// Off for the developer shortcut in Settings: the RevenueCat impression would otherwise
    /// count a paywall opened only to look at it.
    var tracksAnalytics: Bool = true
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    var onDismissed: (() -> Void)? = nil

    @State private var purchasing = false
    @State private var appeared = false
    @State private var showClose = false

    private let context = SophiaPaywallContext.blocker

    private var prices: StoreViewModel.PaywallPriceDisplay {
        store.paywallPriceDisplay(language: languageManager.current)
    }

    /// The offering served here may come from a RevenueCat experiment without an intro offer.
    private var hasTrial: Bool {
        store.annualHasFreeTrial(forOfferingIdentifier: context.offeringIdentifier)
    }

    /// The trial length of the product actually sold here, so « 3 jours » follows the store.
    private var trialDays: Int {
        store.trialDays(for: store.annualPackage(forOfferingIdentifier: context.offeringIdentifier)) ?? store.annualTrialDays
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    closeButton
                        .opacity(showClose ? 1 : 0)
                        .allowsHitTesting(showClose)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 22) {
                        hero
                        headline.padding(.horizontal, 28)
                        PaywallUnlockList(titleKey: "paywall.unlock.plus", items: [.audio, .unlimited, .quiz])
                            .padding(.horizontal, 22)
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                }
                .scrollIndicators(.hidden)

                bottomBar
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
            // One column of copy, drawn for an iPhone (see the other native paywalls).
            .frame(maxWidth: OV2.readableWidth)
        }
        .onAppear {
            if tracksAnalytics {
                store.trackPaywallImpression(paywallId: "native_blocker", offeringIdentifier: context.offeringIdentifier)
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
            // La croix n'apparaît qu'au bout de 2 s, le temps de voir la valeur.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.4)) { showClose = true }
            }
        }
        .task {
            if store.offerings == nil { await store.loadOfferingsWithRetry() }
        }
    }

    // MARK: Hero

    /// Le téléphone barré, puis les apps grisées : la même image que la feuille d'avant.
    private var hero: some View {
        VStack(spacing: 18) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 84, height: 84)
                .background(DS.accentTint, in: Circle())
            AntiScrollLockedApps(tileSize: 46, spacing: 10)
        }
    }

    // MARK: Headline

    private var headline: some View {
        VStack(spacing: 10) {
            Text(languageManager.text("paywall.blocker.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(hasTrial
                 ? languageManager.trialText("paywall.blocker.subtitle", days: trialDays)
                 : languageManager.text("paywall.blocker.subtitle.noTrial"))
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(hasTrial ? DS.success : DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            PaywallPriceFootnote(text: priceLine)

            Button(action: purchase) {
                HStack(spacing: 8) {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: hasTrial ? "lock.open.fill" : "sparkles")
                            .font(.jakarta(size: 15, weight: .bold))
                        Text(ctaTitle)
                    }
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .disabled(purchasing)
            .padding(.horizontal, 24)

            PaywallLegalRow(onRestore: restore)
                .padding(.bottom, 14)
        }
    }

    private var priceLine: String {
        String(
            format: hasTrial
                ? languageManager.trialText("paywall.price.trialThenYearly", days: trialDays)
                : languageManager.text("paywall.price.yearlyNoTrial"),
            prices.yearlyPrice
        )
    }

    /// « Continuer pour 0,00 € » while the trial is served: what today costs, in the store's
    /// currency. Without a trial the button says what it does.
    private var ctaTitle: String {
        hasTrial
            ? String(format: languageManager.text("paywall.cta.continueFor"), store.zeroPriceString(language: languageManager.current))
            : languageManager.text("paywall.cta.subscribe")
    }

    private var closeButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onDismissed?()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.inkSecondary)
                .frame(width: 40, height: 40)
                .background(DS.surface, in: Circle())
                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
        }
    }

    // MARK: Actions

    private func purchase() {
        guard !purchasing else { return }
        guard let package = store.annualPackage(forOfferingIdentifier: context.offeringIdentifier) else {
            Task { await store.loadOfferingsWithRetry() }
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        purchasing = true
        Task {
            let ok = await store.purchase(package: package)
            purchasing = false
            if ok {
                onPurchased()
            }
        }
    }

    private func restore() {
        Task {
            await store.restore()
            if store.isPremium { onRestored() }
        }
    }
}
