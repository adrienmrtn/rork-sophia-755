import Foundation
import Observation
import RevenueCat

@Observable
class StoreViewModel {
    var offerings: Offerings?
    var isPremium: Bool = false
    /// Active Premium entitlement currently in a free-trial period.
    var isInFreeTrial: Bool = false
    /// True when the free trial expires tomorrow (calendar day) — drives the in-app mini banner.
    var trialExpiresInOneDay: Bool = false
    var isLoading: Bool = false
    var isPurchasing: Bool = false
    var error: String?

    init() {
        Task { await listenForUpdates() }
        Task { await loadOfferingsWithRetry() }
    }

    private func listenForUpdates() async {
        for await info in Purchases.shared.customerInfoStream {
            applyCustomerInfo(info)
        }
    }

    private func applyCustomerInfo(_ info: CustomerInfo) {
        let entitlement = info.entitlements["premium"]
        isPremium = entitlement?.isActive == true
        isInFreeTrial = isPremium && entitlement?.periodType == .trial
        trialExpiresInOneDay = Self.isTrialExpiringInOneDay(entitlement)
    }

    /// Calendar-day check: trial is active and expires tomorrow.
    private static func isTrialExpiringInOneDay(_ entitlement: EntitlementInfo?) -> Bool {
        guard let entitlement,
              entitlement.isActive,
              entitlement.periodType == .trial,
              let expiration = entitlement.expirationDate else { return false }
        let calendar = Calendar.current
        let startToday = calendar.startOfDay(for: Date())
        let startExpiration = calendar.startOfDay(for: expiration)
        let days = calendar.dateComponents([.day], from: startToday, to: startExpiration).day
        return days == 1
    }

    func fetchOfferings() async {
        isLoading = true
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    /// Charge les offres en réessayant quelques fois.
    ///
    /// Une seule tentative au lancement suffisait à condamner les paywalls de tout
    /// l'onboarding : sans `offerings`, le bouton d'achat ne trouvait aucun `Package` et ne
    /// faisait **rien** (bouton mort, sans message). Un réseau lent au démarrage — cas
    /// courant sur un appareil de test — suffisait à déclencher ça.
    func loadOfferingsWithRetry() async {
        for attempt in 0..<4 {
            if attempt > 0 {
                let seconds = UInt64(1 << attempt) // 2 s, 4 s, 8 s
                try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            }
            await fetchOfferings()
            if offerings?.current != nil { return }
        }
    }

    func purchase(package: Package) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                applyCustomerInfo(result.customerInfo)
                return isPremium
            }
            return false
        } catch ErrorCode.purchaseCancelledError {
            return false
        } catch ErrorCode.paymentPendingError {
            return false
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func restore() async {
        do {
            let info = try await Purchases.shared.restorePurchases()
            applyCustomerInfo(info)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func checkStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            applyCustomerInfo(info)
        } catch {
            self.error = error.localizedDescription
        }
    }

    var monthlyPackage: Package? {
        offerings?.current?.package(identifier: "$rc_monthly")
    }

    var annualPackage: Package? {
        offerings?.current?.package(identifier: "$rc_annual")
    }

    var promoPackage: Package? {
        offerings?.offering(identifier: "offre_discount")?.package(identifier: "$rc_annual")
    }

    /// Offering matching a context identifier (e.g. `quizz`, `debloquer_cours`), if loaded.
    func offering(identifier: String) -> Offering? {
        guard let offerings else { return nil }
        return offerings.all[identifier] ?? offerings.offering(identifier: identifier)
    }

    /// Annual package for a specific offering identifier, falling back to the current
    /// offering's annual package. Pricing follows whichever offering RevenueCat serves, so a
    /// price/trial experiment on this context is reflected automatically.
    func annualPackage(forOfferingIdentifier identifier: String) -> Package? {
        offering(identifier: identifier)?.package(identifier: "$rc_annual") ?? annualPackage
    }

    // MARK: - Trial awareness

    /// Whether a package's store product ships a free-trial introductory offer.
    ///
    /// Paywall copy must never promise a free trial the served product doesn't have: RevenueCat
    /// experiments can assign an offering whose products have no introductory offer, in which
    /// case the user is charged immediately.
    func hasFreeTrial(_ package: Package?) -> Bool {
        package?.storeProduct.introductoryDiscount?.paymentMode == .freeTrial
    }

    /// Whether the annual package served for a paywall context includes a free trial.
    func annualHasFreeTrial(forOfferingIdentifier identifier: String) -> Bool {
        hasFreeTrial(annualPackage(forOfferingIdentifier: identifier))
    }

    /// Whether the current offering's annual package includes a free trial.
    var annualHasFreeTrial: Bool { hasFreeTrial(annualPackage) }

    /// Marks the customer as exposed to their experiment variant. RevenueCat only counts
    /// impressions automatically for its own paywall templates, so every native paywall here must
    /// report itself or enrolled customers are dropped from experiment results.
    ///
    /// Call once per presentation (not from a callback that can fire repeatedly).
    func trackPaywallImpression(paywallId: String, offeringIdentifier: String? = nil) {
        let resolved = offeringIdentifier.flatMap { offering(identifier: $0) } ?? offerings?.current
        guard let resolved else { return }
        Purchases.shared.trackCustomPaywallImpression(
            CustomPaywallImpressionParams(paywallId: paywallId, offering: resolved)
        )
    }

    // MARK: - Discount (offre_discount) pricing

    struct DiscountPriceDisplay {
        /// Promo price, per month (e.g. "1,67 €") — what the paywall leads with.
        let promoPerMonth: String
        /// Regular annual price, per month, shown struck-through (e.g. "3,33 €").
        let regularPerMonth: String?
        /// "facturé 19,99 € par an" — the amount actually charged, which the per-month
        /// headline must never replace: it is the App Store's rule (3.1.2) and the honest
        /// thing to show for a plan billed once a year.
        let billedYearlyNote: String
        /// Savings badge like "-50%", when computable.
        let discountBadge: String?
    }

    func discountPriceDisplay(language: AppLanguage) -> DiscountPriceDisplay {
        guard let promo = promoPackage?.storeProduct else {
            let fallback = AppLocalizable.string("paywall.discount.fallbackPrice", language: language)
            let regularProduct: StoreProduct? = annualPackage?.storeProduct
            return DiscountPriceDisplay(
                promoPerMonth: fallback,
                regularPerMonth: regularProduct.map { perMonthPrice($0, language: language) },
                billedYearlyNote: billedYearlyNote(fallback, language: language),
                discountBadge: nil
            )
        }
        let regular: StoreProduct? = annualPackage?.storeProduct
        var badge: String? = nil
        if let regular, regular.price > 0, regular.price > promo.price {
            let ratio = (regular.price - promo.price) / regular.price
            let percent = Int((ratio as NSDecimalNumber).doubleValue * 100)
            if percent > 0 { badge = "-\(percent)%" }
        }
        return DiscountPriceDisplay(
            promoPerMonth: perMonthPrice(promo, language: language),
            regularPerMonth: regular.map { perMonthPrice($0, language: language) },
            billedYearlyNote: billedYearlyNote(promo.localizedPriceString, language: language),
            discountBadge: badge
        )
    }

    /// Logs current offering packages and whether StoreKit reports an intro offer (for trial diagnostics).
    func logOnboardingPurchaseDiagnostics() {
        guard let offerings else {
            print("[OnboardingPaywall] offerings is nil — fetchOfferings may have failed: \(error ?? "unknown")")
            return
        }

        let available = offerings.all.keys.sorted().joined(separator: ", ")
        let currentID = offerings.current?.identifier ?? "nil"
        print("[OnboardingPaywall] RC offerings available: [\(available)] — current: \(currentID)")

        for (label, package) in [("annual", annualPackage), ("monthly", monthlyPackage)] {
            guard let package else {
                print("[OnboardingPaywall] \(label) package missing in current offering '\(currentID)'")
                continue
            }
            let product = package.storeProduct
            let intro = product.introductoryDiscount
            let introSummary: String
            if let intro {
                let period = intro.subscriptionPeriod
                introSummary = "\(intro.paymentMode) \(intro.numberOfPeriods)x \(period.value) \(period.unit) @ \(intro.localizedPriceString)"
            } else {
                introSummary = "none (check App Store intro offer + RC product link, or sandbox trial already consumed)"
            }
            print("[OnboardingPaywall] \(label) id=\(package.identifier) price=\(product.localizedPriceString) intro=\(introSummary)")
        }
    }

    struct PaywallPriceDisplay {
        let yearlyPrice: String
        /// "3,33 € / mois" — the annual plan's monthly equivalent, which the plan rows lead
        /// with: a yearly plan is compared against a monthly one, so both have to be read in
        /// the same unit.
        let yearlyPerMonth: String
        /// "facturé 39,99 € par an". The per-month headline never stands alone — the amount
        /// actually charged stays on screen (App Store 3.1.2).
        let yearlyBilledNote: String
        let monthlyPrice: String
        let discountBadge: String?
    }

    func paywallPriceDisplay(language: AppLanguage) -> PaywallPriceDisplay {
        if let annual = annualPackage?.storeProduct,
           let monthly = monthlyPackage?.storeProduct {
            let perMonthLabel = AppLocalizable.string("paywall.plan.perMonth", language: language)
            return PaywallPriceDisplay(
                yearlyPrice: annual.localizedPriceString,
                yearlyPerMonth: "\(perMonthPrice(annual, language: language)) \(perMonthLabel)",
                yearlyBilledNote: billedYearlyNote(annual.localizedPriceString, language: language),
                monthlyPrice: monthly.localizedPriceString,
                discountBadge: savingsBadge(annual: annual.price, monthly: monthly.price)
            )
        }
        return Self.fallbackPaywallPrices(language: language)
    }

    // MARK: - Prix mensuel équivalent

    /// Douzième du prix annuel, écrit comme la boutique de ce client l'écrirait.
    ///
    /// Le formateur vient du produit lui-même (`StoreProduct.priceFormatter`), donc de la
    /// boutique App Store servie : devise **et** conventions du pays. Une table
    /// devise → locale ne peut pas faire ça — un client allemand et un client irlandais
    /// paient tous les deux en euros et ne les écrivent pas pareil (« 3,33 € » contre
    /// « €3.33 ») — elle ne sert plus que de filet si StoreKit ne fournit pas de formateur.
    func perMonthPrice(_ product: StoreProduct, language: AppLanguage) -> String {
        let amount = product.price / 12
        if let formatter = product.priceFormatter,
           let text = formatter.string(from: amount as NSDecimalNumber) {
            return text
        }
        let locale = pricingLocale(annualCurrencyCode: product.currencyCode, language: language)
        return formatCurrency(amount, currencyCode: product.currencyCode, locale: locale)
    }

    /// « facturé 39,99 € par an » — ce que la boutique prélèvera réellement.
    private func billedYearlyNote(_ yearlyPrice: String, language: AppLanguage) -> String {
        String(
            format: AppLocalizable.string("paywall.plan.billedYearly", language: language),
            yearlyPrice
        )
    }

    private func pricingLocale(annualCurrencyCode: String?, language: AppLanguage) -> Locale {
        if let code = annualCurrencyCode {
            switch code {
            case "EUR": return Locale(identifier: "fr_FR")
            case "GBP": return Locale(identifier: "en_GB")
            case "USD": return Locale(identifier: "en_US")
            default: break
            }
        }
        return Locale(identifier: language.localeIdentifier)
    }

    private func formatCurrency(_ amount: Decimal, currencyCode: String?, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    private func savingsBadge(annual: Decimal, monthly: Decimal) -> String? {
        guard monthly > 0 else { return nil }
        let fullYearAtMonthly = monthly * 12
        guard fullYearAtMonthly > annual else { return nil }
        let ratio = (fullYearAtMonthly - annual) / fullYearAtMonthly
        let percent = Int((ratio as NSDecimalNumber).doubleValue * 100)
        guard percent > 0 else { return nil }
        return "-\(percent)%"
    }

    private static func fallbackPaywallPrices(language: AppLanguage) -> PaywallPriceDisplay {
        let yearly = AppLocalizable.string("paywall.plan.fallback.yearlyPrice", language: language)
        return PaywallPriceDisplay(
            yearlyPrice: yearly,
            yearlyPerMonth: AppLocalizable.string("paywall.plan.fallback.yearlyMonthly", language: language),
            yearlyBilledNote: String(
                format: AppLocalizable.string("paywall.plan.billedYearly", language: language),
                yearly
            ),
            monthlyPrice: AppLocalizable.string("paywall.plan.fallback.monthlyPrice", language: language),
            discountBadge: AppLocalizable.string("paywall.plan.discount", language: language)
        )
    }
}
