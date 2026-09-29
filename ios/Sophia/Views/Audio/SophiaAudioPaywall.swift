import SwiftUI
import RevenueCat

/// Native paywall for the `audio` context: a free user tapped "Écouter", "Ajouter à la
/// file" or "Télécharger". It sells listening itself — lock screen, five languages, speed,
/// offline — over the cover of the course they wanted to hear.
///
/// Like every context paywall, it sells the annual plan of the offering RevenueCat
/// currently serves (price experiments apply), with an `audio` offering as fallback; the
/// impression and the purchase report that same offering.
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

    @State private var purchasing = false
    @State private var appeared = false
    @State private var cover: UIImage?

    private let context = SophiaPaywallContext.audio

    private var prices: StoreViewModel.PaywallPriceDisplay {
        store.paywallPriceDisplay(language: languageManager.current)
    }

    private var hasTrial: Bool {
        store.annualHasFreeTrial(forOfferingIdentifier: context.offeringIdentifier)
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    closeButton
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 24) {
                        hero
                        headline.padding(.horizontal, 28)
                        features.padding(.horizontal, 24)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                }
                .scrollIndicators(.hidden)

                bottomBar
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
            .frame(maxWidth: OV2.readableWidth)
        }
        .onAppear {
            if let course { cover = CourseImageMap.loadImage(for: course.id) }
            if tracksAnalytics {
                store.trackPaywallImpression(paywallId: "native_audio", offeringIdentifier: context.offeringIdentifier)
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
        .task {
            if store.offerings == nil { await store.loadOfferingsWithRetry() }
        }
    }

    // MARK: Hero

    /// The cover of the course they wanted to hear, with the headphones on it; the bare
    /// headphones when the paywall was opened without a course.
    @ViewBuilder
    private var hero: some View {
        if let cover {
            Image(uiImage: cover)
                .resizable()
                .scaledToFill()
                .frame(width: 180, height: 180)
                .clipShape(.rect(cornerRadius: DS.Radius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "headphones")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(DS.accent, in: Circle())
                        .overlay { Circle().strokeBorder(DS.canvas, lineWidth: 3) }
                        .offset(x: 14, y: 14)
                }
                .dsSoftShadow()
                .padding(.bottom, 8)
        } else {
            Image(systemName: "headphones")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 92, height: 92)
                .background(DS.accentTint, in: Circle())
        }
    }

    // MARK: Headline

    private var headline: some View {
        VStack(spacing: 10) {
            Text(languageManager.text("paywall.audio.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(languageManager.text("paywall.audio.subtitle"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Features

    private var features: some View {
        VStack(alignment: .leading, spacing: 16) {
            featureRow(icon: "lock.iphone", key: "paywall.audio.feature1")
            featureRow(icon: "globe", key: "paywall.audio.feature2")
            featureRow(icon: "speedometer", key: "paywall.audio.feature3")
            featureRow(icon: "arrow.down.circle", key: "paywall.audio.feature4")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
    }

    private func featureRow(icon: String, key: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.accentSoft)
                .frame(width: 36, height: 36)
                .background(DS.accentTint, in: Circle())
            Text(languageManager.text(key))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Text(priceLine)
                .font(DS.sans(.footnote, .medium))
                .foregroundStyle(DS.inkTertiary)
                .multilineTextAlignment(.center)

            Button(action: purchase) {
                HStack(spacing: 8) {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: hasTrial ? "lock.open.fill" : "headphones")
                            .font(.jakarta(size: 15, weight: .bold))
                        Text(languageManager.text(hasTrial ? "paywall.cta.unlockFree" : "paywall.cta.subscribe"))
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
                ? languageManager.trialText("paywall.price.trialThenYearly", days: store.annualTrialDays)
                : languageManager.text("paywall.price.yearlyNoTrial"),
            prices.yearlyPrice
        )
    }

    private var closeButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
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
