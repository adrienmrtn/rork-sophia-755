import RevenueCat
import SwiftUI
import UIKit

// Socle commun des paywalls « Elevate arrondi » (cours, quiz, audio, anti-scroll) : l'écran
// (contenu qui défile, CTA et mentions épinglés en bas), le choix de formule, le bloc d'essai
// gratuit et la logique d'achat, la même pour tous. Les blocs de contenu (en-tête avant /
// après, experts, avis…) sont dans `ElevatePaywallBlocks.swift`.

// MARK: - Formules

/// Les deux formules d'un paywall : l'annuelle et la courte (mensuelle, ou hebdomadaire quand
/// l'offre servie porte un plan hebdo à la place).
nonisolated enum ElevatePaywallPlan: Sendable {
    case yearly
    case short
}

/// Les deux mises en page de la partie « formules » et du bas d'écran.
nonisolated enum ElevatePaywallLayout: Sendable {
    /// Cartes à bandeau, bloc « Offre spéciale », mentions légales sous le CTA. La croix est en
    /// haut à droite, posée sur l'en-tête avant / après qui monte jusqu'au bord de l'écran.
    case bonhomme
    /// Cartes compactes, « Annule à tout moment » et liens légaux dans le contenu, croix en
    /// haut à gauche.
    case reviews
}

/// Ce que le paywall vend, lu dans l'offre réellement servie : les deux produits, leurs prix
/// écrits par la boutique, la durée d'essai de chacun. Aucun montant en dur.
struct ElevatePaywallOffer {
    let annual: Package?
    /// Plan court de la même offre ; `nil` quand elle n'en sert pas (la carte n'apparaît pas).
    let short: Package?
    let shortIsWeekly: Bool
    /// « 39,99 € »
    let yearlyPrice: String
    /// Le prix annuel ramené à la semaine, puis au mois.
    let yearlyPerWeek: String
    let yearlyPerMonth: String
    /// « 7,99 € »
    let shortPrice: String
    /// Le plan court ramené à la semaine (lui-même s'il est hebdomadaire).
    let shortPerWeek: String
    /// « 58% » : ce que l'annuel économise sur un an de plan court.
    let savings: String?
    /// Jours d'essai gratuit de chaque produit ; `nil` quand il n'en a pas.
    let yearlyTrialDays: Int?
    let shortTrialDays: Int?

    init(store: StoreViewModel, offeringIdentifier: String, language: AppLanguage) {
        let annualPackage: Package? = store.annualPackage(forOfferingIdentifier: offeringIdentifier)
        let offering: Offering? = store.displayedOffering(forContextIdentifier: offeringIdentifier)
        let monthly: Package? = offering?.package(identifier: "$rc_monthly")
        let weekly: Package? = offering?.package(identifier: "$rc_weekly")
        // Pas de plan court sans plan annuel à côté : c'est l'annuel que ces paywalls vendent.
        let shortPackage: Package? = annualPackage == nil ? nil : (monthly ?? weekly)
        let weeklyOnly: Bool = shortPackage != nil && monthly == nil

        annual = annualPackage
        short = shortPackage
        shortIsWeekly = weeklyOnly
        yearlyTrialDays = store.trialDays(for: annualPackage)
        shortTrialDays = store.trialDays(for: shortPackage)

        if let product = annualPackage?.storeProduct {
            yearlyPrice = product.localizedPriceString
            yearlyPerWeek = store.perWeekPrice(product, language: language)
            yearlyPerMonth = store.perMonthPrice(product, language: language)
        } else {
            yearlyPrice = StoreViewModel.unknownPrice
            yearlyPerWeek = StoreViewModel.unknownPrice
            yearlyPerMonth = StoreViewModel.unknownPrice
        }

        if let product = shortPackage?.storeProduct {
            shortPrice = product.localizedPriceString
            if weeklyOnly {
                shortPerWeek = product.localizedPriceString
            } else {
                let perWeek: Decimal = product.price * Decimal(12) / Decimal(52)
                shortPerWeek = Self.format(perWeek, product: product, language: language)
            }
        } else {
            shortPrice = StoreViewModel.unknownPrice
            shortPerWeek = StoreViewModel.unknownPrice
        }

        if let annualProduct = annualPackage?.storeProduct, let shortProduct = shortPackage?.storeProduct {
            savings = Self.savings(
                annual: annualProduct.price,
                short: shortProduct.price,
                periodsPerYear: weeklyOnly ? 52 : 12
            )
        } else {
            savings = nil
        }
    }

    func trialDays(for plan: ElevatePaywallPlan) -> Int? {
        switch plan {
        case .yearly: return yearlyTrialDays
        case .short: return shortTrialDays
        }
    }

    func package(for plan: ElevatePaywallPlan) -> Package? {
        switch plan {
        case .yearly: return annual
        case .short: return short
        }
    }

    /// Un montant dérivé, écrit comme la boutique écrit ses prix (formateur du produit), avec
    /// un formateur local en filet.
    private static func format(_ amount: Decimal, product: StoreProduct, language: AppLanguage) -> String {
        let number: NSDecimalNumber = amount as NSDecimalNumber
        if let formatter = product.priceFormatter, let text = formatter.string(from: number) {
            return text
        }
        let fallback = NumberFormatter()
        fallback.numberStyle = .currency
        fallback.locale = language.foundationLocale
        if let code = product.currencyCode { fallback.currencyCode = code }
        return fallback.string(from: number) ?? "\(amount)"
    }

    /// Même calcul que le badge du paywall comparatif (`StoreViewModel.savingsBadge`).
    private static func savings(annual: Decimal, short: Decimal, periodsPerYear: Int) -> String? {
        guard short > 0 else { return nil }
        let fullYear: Decimal = short * Decimal(periodsPerYear)
        guard fullYear > annual else { return nil }
        let ratio: Decimal = (fullYear - annual) / fullYear
        let percent: Int = Int((ratio as NSDecimalNumber).doubleValue * 100)
        guard percent > 0 else { return nil }
        return "\(percent)%"
    }
}

// MARK: - Texte à passage en gras

enum ElevateMarkup {
    /// `**…**` → passage en `strong` (et en `strongColor` s'il est donné), le reste en `base`.
    static func text(_ source: String, base: Font, strong: Font, strongColor: Color? = nil) -> Text {
        let parts: [String] = source.components(separatedBy: "**")
        var result: Text = Text(verbatim: "")
        for (index, part) in parts.enumerated() where !part.isEmpty {
            if index % 2 == 1 {
                var piece: Text = Text(verbatim: part).font(strong)
                if let strongColor { piece = piece.foregroundColor(strongColor) }
                result = result + piece
            } else {
                result = result + Text(verbatim: part).font(base)
            }
        }
        return result
    }
}

// MARK: - Écran

/// L'écran commun : le contenu du paywall puis le choix de formule dans une colonne qui
/// défile, le CTA et les mentions épinglés en bas, la croix par-dessus. Il porte toute la
/// logique d'achat, la même que les paywalls qu'il remplace : produit de l'offre servie,
/// rechargement des offres absentes, états d'achat, restauration.
struct ElevatePaywallScreen<Content: View>: View {
    @Environment(LanguageManager.self) private var languageManager

    let store: StoreViewModel
    /// Identifiant d'offre du contexte (`SophiaPaywallContext.offeringIdentifier`).
    let offeringIdentifier: String
    /// Identifiant de paywall envoyé à RevenueCat et à l'événement `paywall_view`.
    let paywallId: String
    /// Propriétés ajoutées à l'impression et aux événements d'achat (variante d'un test A/B).
    var analyticsProps: [String: AnalyticsValue] = [:]
    var tracksAnalytics: Bool = true
    /// Secondes avant que la croix n'apparaisse : trois sur tous les paywalls (0 : tout de suite).
    var closeDelay: Double = PaywallClose.delay
    var layout: ElevatePaywallLayout = .bonhomme
    var onPurchased: () -> Void = {}
    var onRestored: () -> Void = {}
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var selected: ElevatePaywallPlan = .yearly
    @State private var purchasing = false
    @State private var showClose = false
    @State private var didAppear = false

    private var offer: ElevatePaywallOffer {
        ElevatePaywallOffer(store: store, offeringIdentifier: offeringIdentifier, language: languageManager.current)
    }

    /// Le plan court choisi n'existe plus (offres rechargées) : on revient à l'annuel.
    private func effectivePlan(_ offer: ElevatePaywallOffer) -> ElevatePaywallPlan {
        selected == .short && offer.short != nil ? .short : .yearly
    }

    var body: some View {
        let offer: ElevatePaywallOffer = self.offer
        let plan: ElevatePaywallPlan = effectivePlan(offer)
        let bleed: Edge.Set = layout == .bonhomme ? .top : []
        let closeAlignment: Alignment = layout == .reviews ? .topLeading : .topTrailing

        return ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        content()
                        plansSection(offer: offer, plan: plan)
                    }
                    .padding(.top, layout == .reviews ? 62 : 0)
                }
                .scrollIndicators(.hidden)
                .ignoresSafeArea(.container, edges: bleed)

                bottomBar(offer: offer, plan: plan)
            }
            .overlay(alignment: closeAlignment) {
                closeButton
                    .padding(.horizontal, layout == .reviews ? 20 : 14)
                    .padding(.top, layout == .reviews ? 14 : 10)
                    .opacity(showClose ? 1 : 0)
                    .allowsHitTesting(showClose)
            }
            // Une colonne dessinée pour un iPhone : bornée et centrée sur tablette, le fond
            // restant plein cadre.
            .frame(maxWidth: OV2.readableWidth)
        }
        .onAppear { appear() }
        .task {
            if store.offerings == nil { await store.loadOfferingsWithRetry() }
        }
    }

    private func appear() {
        guard !didAppear else { return }
        didAppear = true
        if tracksAnalytics {
            store.trackPaywallImpression(
                paywallId: paywallId,
                offeringIdentifier: offeringIdentifier,
                extraProps: analyticsProps
            )
        }
        if closeDelay <= 0 {
            showClose = true
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + closeDelay) {
                withAnimation(.easeOut(duration: 0.4)) { showClose = true }
            }
        }
    }

    // MARK: Croix

    private var closeButton: some View {
        Button {
            Haptics.tap()
            onClose()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.inkSecondary)
                .frame(width: 44, height: 44)
                .background(layout == .reviews ? DS.surface : DS.surface.opacity(0.9), in: Circle())
                .overlay {
                    if layout == .reviews {
                        Circle().strokeBorder(DS.hairline, lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(PressableStyle(scale: 0.9, haptic: false))
        .accessibilityLabel(Text(languageManager.text("common.close")))
    }

    // MARK: Formules

    @ViewBuilder
    private func plansSection(offer: ElevatePaywallOffer, plan: ElevatePaywallPlan) -> some View {
        switch layout {
        case .bonhomme:
            bonhommePlans(offer: offer, plan: plan)
        case .reviews:
            reviewsPlans(offer: offer, plan: plan)
        }
    }

    private func bonhommePlans(offer: ElevatePaywallOffer, plan: ElevatePaywallPlan) -> some View {
        VStack(spacing: 12) {
            Text(languageManager.text("paywall.elevate.common.plans.title"))
                .font(DS.title(.title3, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)

            ElevatePlanCardBanded(
                band: yearlyBand(offer),
                name: languageManager.text("paywall.plan.yearly"),
                price: offer.yearlyPrice,
                perWeek: offer.yearlyPerWeek,
                perWeekUnit: languageManager.text("paywall.plan.perWeek"),
                isSelected: plan == .yearly,
                action: { select(.yearly) }
            )

            if offer.short != nil {
                ElevatePlanCardBanded(
                    band: languageManager.text("paywall.plan.monthlySubtitle"),
                    name: shortPlanName(offer),
                    price: offer.shortPrice,
                    perWeek: offer.shortPerWeek,
                    perWeekUnit: languageManager.text("paywall.plan.perWeek"),
                    isSelected: plan == .short,
                    action: { select(.short) }
                )
            }

            // Le bloc d'essai ne se montre que si le produit choisi en porte un.
            if let days: Int = offer.trialDays(for: plan) {
                ElevateTrialOfferCard(days: days)
                    .padding(.top, 6)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }

    private func reviewsPlans(offer: ElevatePaywallOffer, plan: ElevatePaywallPlan) -> some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(languageManager.text("paywall.elevate.common.plans.title"))
                    .font(DS.title(.title3, .semibold))
                    .foregroundStyle(DS.ink)
                    .accessibilityAddTraits(.isHeader)
                if let days: Int = sharedTrialDays(offer) {
                    Text(languageManager.trialText("paywall.elevate.reviews.plans.subtitle", days: days))
                        .font(DS.sans(.subheadline, .regular))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.bottom, 4)

            ElevatePlanCardCompact(
                badge: yearlyBand(offer),
                name: languageManager.text("paywall.plan.yearly"),
                detail: offer.yearlyPrice + " " + languageManager.text("paywall.plan.perYear"),
                price: offer.shortIsWeekly ? offer.yearlyPerWeek : offer.yearlyPerMonth,
                unit: languageManager.text(offer.shortIsWeekly ? "paywall.plan.perWeek" : "paywall.plan.perMonth"),
                isSelected: plan == .yearly,
                action: { select(.yearly) }
            )

            if offer.short != nil {
                ElevatePlanCardCompact(
                    badge: nil,
                    name: shortPlanName(offer),
                    detail: languageManager.text("paywall.plan.monthlySubtitle"),
                    price: offer.shortPrice,
                    unit: languageManager.text(offer.shortIsWeekly ? "paywall.plan.perWeek" : "paywall.plan.perMonth"),
                    isSelected: plan == .short,
                    action: { select(.short) }
                )
            }

            Text(languageManager.text("paywall.cancelAnytime"))
                .font(DS.sans(.footnote, .regular))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)

            ElevatePaywallLegalLinks(order: .termsPrivacyRestore, spread: false, onRestore: restore)
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }

    /// « Économise 58 % », ou rien quand l'offre ne sert pas de plan court à comparer.
    private func yearlyBand(_ offer: ElevatePaywallOffer) -> String? {
        guard let savings: String = offer.savings else { return nil }
        return String(format: languageManager.text("onboardingV2.pw.save"), savings)
    }

    private func shortPlanName(_ offer: ElevatePaywallOffer) -> String {
        languageManager.text(offer.shortIsWeekly ? "onboardingV2.pw.weekly" : "paywall.plan.monthly")
    }

    /// La durée d'essai quand toutes les formules affichées offrent la même ; sinon `nil`
    /// (la phrase « quelle que soit la formule » serait fausse).
    private func sharedTrialDays(_ offer: ElevatePaywallOffer) -> Int? {
        guard let yearly: Int = offer.yearlyTrialDays else { return nil }
        if offer.short == nil { return yearly }
        return offer.shortTrialDays == yearly ? yearly : nil
    }

    private func select(_ plan: ElevatePaywallPlan) {
        guard selected != plan else { return }
        Haptics.select()
        withAnimation(DS.Motion.snappy) { selected = plan }
    }

    // MARK: Bas d'écran

    private func bottomBar(offer: ElevatePaywallOffer, plan: ElevatePaywallPlan) -> some View {
        let hasTrial: Bool = offer.trialDays(for: plan) != nil
        return VStack(spacing: 8) {
            Button(action: purchase) {
                HStack(spacing: 10) {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "lock")
                            .font(.system(size: 16, weight: .semibold))
                        Text(languageManager.text(hasTrial ? "paywall.cta.unlockFree" : "paywall.cta.subscribe"))
                            .font(DS.sans(.headline, .semibold))
                            .tracking(0.4)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.center)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .frame(minHeight: 56)
                .background(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous).fill(DS.accent))
            }
            .buttonStyle(PressableStyle(scale: 0.96, haptic: false))
            .disabled(purchasing)

            VStack(spacing: 2) {
                Text(priceLine(offer: offer, plan: plan))
                    .font(DS.sans(.footnote, layout == .reviews ? .semibold : .regular))
                if layout == .bonhomme && hasTrial {
                    Text(languageManager.text("paywall.cancelAnytime"))
                        .font(DS.sans(.footnote, .regular))
                }
            }
            .foregroundStyle(DS.inkSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)

            if layout == .bonhomme {
                ElevatePaywallLegalLinks(order: .termsRestorePrivacy, spread: true, onRestore: restore)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, layout == .reviews ? 12 : 4)
        .background(DS.canvas)
        .overlay(alignment: .top) {
            Rectangle().fill(DS.hairline).frame(height: 1)
        }
    }

    /// Ce que la boutique prélève, et quand : « Essai gratuit de 3 jours, puis 39,99 € / an »,
    /// ou la formule sans essai quand le produit servi n'en a pas.
    private func priceLine(offer: ElevatePaywallOffer, plan: ElevatePaywallPlan) -> String {
        switch plan {
        case .yearly:
            let format: String
            if let days: Int = offer.yearlyTrialDays {
                format = languageManager.trialText("paywall.price.trialThenYearly", days: days)
            } else {
                format = languageManager.text("paywall.price.yearlyNoTrial")
            }
            return String(format: format, offer.yearlyPrice)
        case .short:
            if offer.shortIsWeekly {
                // Pas de phrase dédiée au plan hebdomadaire : le prix et son unité, précédés
                // des jours offerts quand il y en a.
                let price: String = offer.shortPrice + " " + languageManager.text("paywall.plan.perWeek")
                if let days: Int = offer.shortTrialDays {
                    return languageManager.trialText("onboardingV2.pw.trialBadge", days: days) + " · " + price
                }
                return price
            }
            let format: String
            if let days: Int = offer.shortTrialDays {
                format = languageManager.trialText("paywall.elevate.common.price.trialThenMonthly", days: days)
            } else {
                format = languageManager.text("paywall.elevate.common.price.monthlyNoTrial")
            }
            return String(format: format, offer.shortPrice)
        }
    }

    // MARK: Achat

    private func purchase() {
        guard !purchasing else { return }
        let offer: ElevatePaywallOffer = self.offer
        // Offres pas encore chargées : on les recharge au lieu d'un bouton qui ne fait rien.
        guard let package: Package = offer.package(for: effectivePlan(offer)) else {
            Task { await store.loadOfferingsWithRetry() }
            return
        }
        Haptics.confirm()
        purchasing = true
        Task {
            let ok: Bool = await store.purchase(package: package, paywallId: paywallId, analyticsProps: analyticsProps)
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

// MARK: - Cartes de formule

/// Pastille ronde de sélection, cochée (variante bonhomme) ou à point (variante avis).
private struct ElevatePlanRadio: View {
    let isSelected: Bool
    let dotStyle: Bool

    var body: some View {
        ZStack {
            if dotStyle {
                Circle().strokeBorder(isSelected ? DS.accent : DS.inkTertiary.opacity(0.5), lineWidth: 2)
                Circle().fill(DS.accent).frame(width: 12, height: 12).opacity(isSelected ? 1 : 0)
            } else if isSelected {
                Circle().fill(DS.accent)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Circle().fill(DS.surface)
                Circle().strokeBorder(DS.inkTertiary.opacity(0.5), lineWidth: 2)
            }
        }
        .frame(width: 24, height: 24)
        .accessibilityHidden(true)
    }
}

/// Carte de formule à bandeau (« ÉCONOMISE 58 % » / « SANS ENGAGEMENT »), le prix à gauche
/// sous le nom, l'équivalent par semaine à droite.
struct ElevatePlanCardBanded: View {
    let band: String?
    let name: String
    let price: String
    let perWeek: String
    let perWeekUnit: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                if let band {
                    Text(band.uppercasedInApp())
                        .font(DS.sans(.caption2, .bold))
                        .tracking(0.9)
                        .foregroundStyle(isSelected ? Color.white : DS.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, minHeight: 26)
                        .background(isSelected ? DS.accent : DS.hairline)
                }
                HStack(spacing: 14) {
                    ElevatePlanRadio(isSelected: isSelected, dotStyle: false)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(DS.sans(.headline, .bold))
                            .foregroundStyle(DS.ink)
                        Text(price)
                            .font(DS.sans(.footnote, .regular))
                            .foregroundStyle(DS.inkSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    perWeekText
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 14)
            }
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            .dsOptionCard(isSelected ? .selected : .idle)
        }
        .buttonStyle(PressableStyle(haptic: false))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var perWeekText: Text {
        let amount: Text = Text(verbatim: perWeek)
            .font(DS.sans(.callout, .bold))
            .foregroundColor(DS.ink)
        let unit: Text = Text(verbatim: " " + perWeekUnit)
            .font(DS.sans(.footnote, .regular))
            .foregroundColor(DS.inkSecondary)
        return amount + unit
    }
}

/// Carte de formule compacte (variante avis) : nom et détail à gauche, prix et unité à
/// droite, pastille « Économise 58 % » à cheval sur le bord haut.
struct ElevatePlanCardCompact: View {
    let badge: String?
    let name: String
    let detail: String
    let price: String
    let unit: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ElevatePlanRadio(isSelected: isSelected, dotStyle: true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(DS.sans(.callout, .bold))
                        .foregroundStyle(DS.ink)
                    Text(detail)
                        .font(DS.sans(.footnote, .regular))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(DS.sans(.headline, .bold))
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(unit)
                        .font(DS.sans(.caption, .regular))
                        .foregroundStyle(DS.inkSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(minHeight: 76)
            .dsOptionCard(isSelected ? .selected : .idle)
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(DS.sans(.caption, .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DS.accent, in: Capsule())
                        .offset(x: -16, y: -11)
                }
            }
        }
        .buttonStyle(PressableStyle(haptic: false))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Bloc « Offre spéciale »

/// « OFFRE SPÉCIALE · 3 jours offerts · Essaie tout gratuitement… », relié aux formules par un
/// petit « + ». La durée vient du produit choisi.
struct ElevateTrialOfferCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let days: Int

    /// Encre fixe sur la pastille ambrée, lisible de jour comme de nuit.
    private static let badgeInk = Color(red: 0.133, green: 0.149, blue: 0.180)

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(languageManager.text("paywall.elevate.common.offer.badge").uppercasedInApp())
                    .font(DS.sans(.caption2, .bold))
                    .tracking(0.55)
                    .foregroundStyle(Self.badgeInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DS.warm, in: Capsule())
                Text(languageManager.trialText("onboardingV2.pw.trialBadge", days: days))
                    .font(DS.sans(.callout, .bold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(languageManager.text("paywall.elevate.common.offer.body"))
                    .font(DS.sans(.footnote, .regular))
                    .foregroundStyle(DS.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image("pw_offer_key")
                .resizable()
                .scaledToFill()
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .rotationEffect(.degrees(4))
                .accessibilityHidden(true)
        }
        .padding(.leading, 16)
        .padding(.trailing, 14)
        .padding(.vertical, 16)
        .dsOptionCard(.idle)
        .overlay(alignment: .top) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(DS.inkSecondary)
                .frame(width: 28, height: 28)
                .background(DS.surface, in: Circle())
                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1.5) }
                .offset(y: -15)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Liens légaux

/// Conditions · Restaurer · Confidentialité, soulignés ; les deux textes s'ouvrent en feuille.
struct ElevatePaywallLegalLinks: View {
    enum Order {
        case termsRestorePrivacy
        case termsPrivacyRestore
    }

    @Environment(LanguageManager.self) private var languageManager
    var order: Order = .termsRestorePrivacy
    /// Répartis sur toute la largeur (sous le CTA) ou regroupés au centre (dans le contenu).
    var spread: Bool = true
    var onRestore: () -> Void

    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        HStack(spacing: spread ? 0 : 12) {
            switch order {
            case .termsRestorePrivacy:
                termsLink
                if spread { Spacer(minLength: 8) }
                restoreLink
                if spread { Spacer(minLength: 8) }
                privacyLink
            case .termsPrivacyRestore:
                termsLink
                privacyLink
                restoreLink
            }
        }
        .padding(.horizontal, spread ? 12 : 0)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showTerms) { TermsView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }

    private var termsLink: some View {
        link(languageManager.text("paywall.terms")) { showTerms = true }
    }

    private var privacyLink: some View {
        link(languageManager.text("paywall.privacy")) { showPrivacy = true }
    }

    private var restoreLink: some View {
        link(languageManager.text("paywall.restore"), action: onRestore)
    }

    private func link(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DS.sans(.caption, .regular))
                .underline()
                .foregroundStyle(DS.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(minHeight: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Croix de fermeture

/// La croix d'un paywall n'apparaît qu'au bout de trois secondes, sur tous les paywalls : le
/// temps de voir l'offre avant de pouvoir la fermer.
enum PaywallClose {
    static let delay: Double = 3
}

/// Cache la croix (invisible et inerte) pendant `PaywallClose.delay`, puis la fait apparaître.
/// Pour les paywalls qui dessinent leur propre croix ; `ElevatePaywallScreen` a son `closeDelay`.
private struct PaywallCloseDelayModifier: ViewModifier {
    @State private var shown: Bool = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .allowsHitTesting(shown)
            .accessibilityHidden(!shown)
            .task {
                guard !shown else { return }
                try? await Task.sleep(for: .seconds(PaywallClose.delay))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.4)) { shown = true }
            }
    }
}

extension View {
    func paywallCloseDelayed() -> some View {
        modifier(PaywallCloseDelayModifier())
    }
}
