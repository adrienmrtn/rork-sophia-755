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
    /// Entitlement still active, but the store says it will not renew: the customer has
    /// cancelled and is running out the period they already have.
    ///
    /// This is the save window, and until now nothing in the app could see it —
    /// `isPremium` alone reads a cancelled subscriber as a happy one. On an annual plan
    /// the window is months; on the 3-day trial it is a day or two, and the person is
    /// still opening the app every one of them.
    var willNotRenew: Bool = false
    /// When the current period ends, for copy that names the date.
    var expiresAt: Date?
    var isLoading: Bool = false
    var isPurchasing: Bool = false
    var error: String?

    init() {
        reportDiscountBucket()
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
        willNotRenew = isPremium && entitlement?.willRenew == false
        expiresAt = entitlement?.expirationDate
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

    var weeklyPackage: Package? {
        offerings?.current?.package(identifier: "$rc_weekly")
    }

    /// The plan sold next to the annual one on the comparison paywall: the monthly plan, or
    /// the weekly plan when the served offering carries a weekly package instead (a
    /// RevenueCat experiment can swap one for the other without an app update).
    var shortPlanPackage: Package? {
        monthlyPackage ?? weeklyPackage
    }

    var shortPlanIsWeekly: Bool {
        monthlyPackage == nil && weeklyPackage != nil
    }

    var annualPackage: Package? {
        offerings?.current?.package(identifier: "$rc_annual")
    }

    // MARK: - Discount A/B bucket

    /// Which flash-discount offering this install sees. Drawn once at random, kept for the
    /// life of the install, and reported to RevenueCat as the `discount_bucket` subscriber
    /// attribute so revenue and conversion split by bucket in the charts. It lives in the
    /// app rather than in a RevenueCat experiment because a customer can only be in one
    /// experiment at a time, and every new customer is already in a price experiment on
    /// the onboarding paywall.
    enum DiscountBucket: String, CaseIterable {
        case a = "A"
        case b = "B"

        /// Offering this bucket sells; bucket A keeps today's `offre_discount`.
        var offeringIdentifier: String {
            switch self {
            case .a: return "offre_discount"
            case .b: return "offre_discount_2999"
            }
        }
    }

    static let discountBucketKey = "sophia_discount_bucket"

    static let discountBucket: DiscountBucket = {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: discountBucketKey),
           let saved = DiscountBucket(rawValue: raw) {
            return saved
        }
        let drawn = DiscountBucket.allCases.randomElement() ?? .a
        defaults.set(drawn.rawValue, forKey: discountBucketKey)
        return drawn
    }()

    /// Offering behind the flash discount paywall: the bucket's offering, or `offre_discount`
    /// while the bucket's own offering does not exist yet in RevenueCat. Explicit by design:
    /// it is never the current offering, so an experiment on the onboarding price leaves it
    /// untouched.
    var promoOffering: Offering? {
        offerings?.offering(identifier: Self.discountBucket.offeringIdentifier)
            ?? offerings?.offering(identifier: DiscountBucket.a.offeringIdentifier)
    }

    /// Tells RevenueCat which bucket this customer is in. Sent at every launch: attributes
    /// are cheap, RevenueCat ignores unchanged values, and a re-send after `logIn` keeps
    /// the identified customer tagged as well as the anonymous one.
    private func reportDiscountBucket() {
        Purchases.shared.attribution.setAttributes(["discount_bucket": Self.discountBucket.rawValue])
    }

    var promoPackage: Package? {
        promoOffering?.package(identifier: "$rc_annual")
    }

    /// Offering matching a context identifier (e.g. `quizz`, `debloquer_cours`), if loaded.
    func offering(identifier: String) -> Offering? {
        guard let offerings else { return nil }
        return offerings.all[identifier] ?? offerings.offering(identifier: identifier)
    }

    /// Offering a context paywall (`quizz`, `debloquer_cours`, `entrainement`) actually displays.
    ///
    /// RevenueCat experiments work by swapping the **current** offering, and the context
    /// offerings carry the same products as `fin_onboarding`: they exist for attribution, not
    /// to sell another price. So a context paywall shows and charges the current offering
    /// whenever it has an annual package, and only falls back to its own offering when the
    /// current one has none. Before this, `paywallPriceDisplay` (current offering) and the
    /// purchase (context offering) could disagree: a customer enrolled in a 59,99 € variant
    /// was shown 59,99 € and charged 39,99 €, and could buy at 39,99 € from any course.
    func displayedOffering(forContextIdentifier identifier: String) -> Offering? {
        if let current = offerings?.current, current.package(identifier: "$rc_annual") != nil {
            return current
        }
        return offering(identifier: identifier)
    }

    /// Annual package a context paywall sells: the served (current) offering first, then the
    /// context offering. See `displayedOffering(forContextIdentifier:)`.
    func annualPackage(forOfferingIdentifier identifier: String) -> Package? {
        displayedOffering(forContextIdentifier: identifier)?.package(identifier: "$rc_annual")
            ?? annualPackage
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

    // MARK: - Trial length

    /// Days of free trial a package's product ships, or nil when it has none. Read from the
    /// store rather than assumed, so copy that names the number (« 3 jours offerts ») follows
    /// whatever the served product carries — a 7-day variant included.
    func trialDays(for package: Package?) -> Int? {
        guard let intro = package?.storeProduct.introductoryDiscount,
              intro.paymentMode == .freeTrial else { return nil }
        let period = intro.subscriptionPeriod
        let unitDays: Int
        switch period.unit {
        case .day: unitDays = 1
        case .week: unitDays = 7
        case .month: unitDays = 30
        case .year: unitDays = 365
        @unknown default: unitDays = 1
        }
        return max(1, period.value * unitDays * max(1, intro.numberOfPeriods))
    }

    /// Days of the annual plan's free trial, for copy; 3 (what the store has always served)
    /// until the products are loaded.
    var annualTrialDays: Int { trialDays(for: annualPackage) ?? 3 }

    /// Marks the customer as exposed to their experiment variant. RevenueCat only counts
    /// impressions automatically for its own paywall templates, so every native paywall here must
    /// report itself or enrolled customers are dropped from experiment results.
    ///
    /// Call once per presentation (not from a callback that can fire repeatedly).
    func trackPaywallImpression(paywallId: String, offeringIdentifier: String? = nil) {
        // The offering reported must be the one on screen, or a customer enrolled in an
        // experiment is never counted as exposed: that is the served offering, resolved the
        // same way the paywall picks its package.
        let resolved = offeringIdentifier.flatMap { displayedOffering(forContextIdentifier: $0) }
            ?? offerings?.current
        trackPaywallImpression(paywallId: paywallId, offering: resolved)
    }

    /// Same, for a paywall that knows exactly which offering it displays (the discount
    /// paywall, whose offering is never the current one).
    func trackPaywallImpression(paywallId: String, offering: Offering?) {
        guard let offering else { return }
        Purchases.shared.trackCustomPaywallImpression(
            CustomPaywallImpressionParams(paywallId: paywallId, offering: offering)
        )
    }
    // MARK: - Discount (offre_discount) pricing

    struct DiscountPriceDisplay {
        /// Promo price, per month (e.g. "1,67 €") — what the paywall leads with.
        let promoPerMonth: String
        /// Regular annual price, per month, shown struck-through (e.g. "3,33 €").
        let regularPerMonth: String?
        /// "facturé 19,99 € par an" — the amount actually charged, kept small under the
        /// per-month headline (App Store 3.1.2).
        let billedYearlyNote: String
        /// Savings badge like "-50%", when computable.
        let discountBadge: String?
    }

    func discountPriceDisplay(language: AppLanguage) -> DiscountPriceDisplay {
        guard let promo = promoPackage?.storeProduct else {
            // Store not answered yet: no number rather than a remembered one.
            let regularProduct: StoreProduct? = annualPackage?.storeProduct
            return DiscountPriceDisplay(
                promoPerMonth: Self.unknownPrice,
                regularPerMonth: regularProduct.map { perMonthPrice($0, language: language) },
                billedYearlyNote: "",
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

        for (label, package) in [("annual", annualPackage), ("monthly", monthlyPackage), ("weekly", weeklyPackage)] {
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
        /// What the store charges for a year (e.g. "39,99 €").
        let yearlyPrice: String
        /// "3,33 € / mois" — the annual plan's monthly equivalent, which the onboarding and
        /// discount paywalls lead with.
        let yearlyPerMonth: String
        /// The annual plan in the short plan's own unit: per month next to a monthly plan,
        /// per week next to a weekly one ("0,77 € / semaine"), so the comparison card reads
        /// in one unit.
        let yearlyPerShortPeriod: String
        /// "facturé 39,99 € par an". The per-month headline never stands alone — the amount
        /// actually charged stays on screen, small and grey (App Store 3.1.2).
        let yearlyBilledNote: String
        /// Price of the short plan (monthly or weekly) as the store writes it.
        let shortPlanPrice: String
        let shortPlanIsWeekly: Bool
        let discountBadge: String?
    }

    func paywallPriceDisplay(language: AppLanguage) -> PaywallPriceDisplay {
        guard let annual = annualPackage?.storeProduct else {
            return Self.fallbackPaywallPrices(language: language)
        }
        let short = shortPlanPackage?.storeProduct
        let weekly = shortPlanIsWeekly
        let perMonthLabel = AppLocalizable.string("paywall.plan.perMonth", language: language)
        let perWeekLabel = AppLocalizable.string("paywall.plan.perWeek", language: language)
        let yearlyPerMonth = "\(perMonthPrice(annual, language: language)) \(perMonthLabel)"
        return PaywallPriceDisplay(
            yearlyPrice: annual.localizedPriceString,
            yearlyPerMonth: yearlyPerMonth,
            yearlyPerShortPeriod: weekly
                ? "\(perWeekPrice(annual, language: language)) \(perWeekLabel)"
                : yearlyPerMonth,
            yearlyBilledNote: billedYearlyNote(annual.localizedPriceString, language: language),
            shortPlanPrice: short?.localizedPriceString ?? Self.unknownPrice,
            shortPlanIsWeekly: weekly,
            discountBadge: short.flatMap {
                savingsBadge(annual: annual.price, shortPlan: $0.price, periodsPerYear: weekly ? 52 : 12)
            }
        )
    }

    // MARK: - Prix mensuel équivalent

    /// Douzième du prix annuel, écrit comme la boutique de ce client l'écrirait : le
    /// formateur vient du produit (`StoreProduct.priceFormatter`), donc devise et
    /// conventions du pays servi. Filet sur un formateur local si StoreKit n'en donne pas.
    func perMonthPrice(_ product: StoreProduct, language: AppLanguage) -> String {
        perPeriodPrice(product, periodsPerYear: 12, language: language)
    }

    /// Fifty-second of the annual price, for the comparison card next to a weekly plan.
    func perWeekPrice(_ product: StoreProduct, language: AppLanguage) -> String {
        perPeriodPrice(product, periodsPerYear: 52, language: language)
    }

    private func perPeriodPrice(_ product: StoreProduct, periodsPerYear: Int, language: AppLanguage) -> String {
        let amount = product.price / Decimal(periodsPerYear)
        if let formatter = product.priceFormatter,
           let text = formatter.string(from: amount as NSDecimalNumber) {
            return text
        }
        return formatCurrency(amount, currencyCode: product.currencyCode, language: language)
    }

    /// « 0,00 € » dans la devise de la boutique : ce que coûte le jour où l'on appuie sur
    /// le bouton quand un essai gratuit est servi.
    func zeroPriceString(language: AppLanguage) -> String {
        if let product = annualPackage?.storeProduct {
            if let formatter = product.priceFormatter,
               let text = formatter.string(from: 0) {
                return text
            }
            return formatCurrency(0, currencyCode: product.currencyCode, language: language)
        }
        return formatCurrency(0, currencyCode: nil, language: language)
    }

    /// « facturé 39,99 € par an » — ce que la boutique prélèvera réellement.
    private func billedYearlyNote(_ yearlyPrice: String, language: AppLanguage) -> String {
        String(
            format: AppLocalizable.string("paywall.plan.billedYearly", language: language),
            yearlyPrice
        )
    }

    /// Filet quand StoreKit ne fournit pas de formateur : le montant s'écrit dans la langue
    /// lue, avec la devise du produit (ou celle de la langue si aucun produit n'est chargé).
    private func formatCurrency(_ amount: Decimal, currencyCode: String?, language: AppLanguage) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: language.localeIdentifier)
        if let currencyCode { formatter.currencyCode = currencyCode }
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    /// « -58 % » : what the annual plan saves against a year of the short plan (twelve
    /// monthly or fifty-two weekly payments).
    private func savingsBadge(annual: Decimal, shortPlan: Decimal, periodsPerYear: Int) -> String? {
        guard shortPlan > 0 else { return nil }
        let fullYearAtMonthly = shortPlan * Decimal(periodsPerYear)
        guard fullYearAtMonthly > annual else { return nil }
        let ratio = (fullYearAtMonthly - annual) / fullYearAtMonthly
        let percent = Int((ratio as NSDecimalNumber).doubleValue * 100)
        guard percent > 0 else { return nil }
        return "-\(percent)%"
    }

    /// What a paywall shows before StoreKit has answered, or when it never does: no number
    /// at all. The old fallback was a hard-coded « 39,99 € » per language, which is wrong the
    /// moment a price experiment or a country tier serves anything else — and a wrong price
    /// on a paywall is worse than a missing one.
    static let unknownPrice = "…"

    private static func fallbackPaywallPrices(language: AppLanguage) -> PaywallPriceDisplay {
        PaywallPriceDisplay(
            yearlyPrice: unknownPrice,
            yearlyPerMonth: unknownPrice,
            yearlyPerShortPeriod: unknownPrice,
            yearlyBilledNote: "",
            shortPlanPrice: unknownPrice,
            shortPlanIsWeekly: false,
            discountBadge: nil
        )
    }
}
