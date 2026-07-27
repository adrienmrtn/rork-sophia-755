import Foundation
import Observation
import RevenueCat

@Observable
class StoreViewModel {
    var offerings: Offerings?
    var isPremium: Bool = false
    var isLoading: Bool = false
    var isPurchasing: Bool = false
    var error: String?

    init() {
        Task { await listenForUpdates() }
        Task { await fetchOfferings() }
    }

    private func listenForUpdates() async {
        for await info in Purchases.shared.customerInfoStream {
            self.isPremium = info.entitlements["premium"]?.isActive == true
        }
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

    func purchase(package: Package) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
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
            isPremium = info.entitlements["premium"]?.isActive == true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func checkStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            isPremium = info.entitlements["premium"]?.isActive == true
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
        /// Promo price for the annual plan (e.g. "19,99 €").
        let promoYearly: String
        /// Regular annual price shown struck-through (e.g. "39,99 €"), when available.
        let regularYearly: String?
        /// Savings badge like "-50%", when computable.
        let discountBadge: String?
    }

    func discountPriceDisplay(language: AppLanguage) -> DiscountPriceDisplay {
        guard let promo = promoPackage?.storeProduct else {
            return DiscountPriceDisplay(
                promoYearly: AppLocalizable.string("paywall.discount.fallbackPrice", language: language),
                regularYearly: annualPackage?.storeProduct.localizedPriceString,
                discountBadge: nil
            )
        }
        let regular = annualPackage?.storeProduct
        var badge: String? = nil
        if let regular, regular.price > 0, regular.price > promo.price {
            let ratio = (regular.price - promo.price) / regular.price
            let percent = Int((ratio as NSDecimalNumber).doubleValue * 100)
            if percent > 0 { badge = "-\(percent)%" }
        }
        return DiscountPriceDisplay(
            promoYearly: promo.localizedPriceString,
            regularYearly: regular?.localizedPriceString,
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
        let yearlyPerMonth: String
        let monthlyPrice: String
        let discountBadge: String?
    }

    func paywallPriceDisplay(language: AppLanguage) -> PaywallPriceDisplay {
        if let annual = annualPackage?.storeProduct,
           let monthly = monthlyPackage?.storeProduct {
            let locale = pricingLocale(annualCurrencyCode: annual.currencyCode, language: language)
            let perMonth = formatCurrency(annual.price / 12, currencyCode: annual.currencyCode, locale: locale)
            let perMonthLabel = AppLocalizable.string("paywall.plan.perMonth", language: language)
            return PaywallPriceDisplay(
                yearlyPrice: annual.localizedPriceString,
                yearlyPerMonth: "\(perMonth) \(perMonthLabel)",
                monthlyPrice: monthly.localizedPriceString,
                discountBadge: savingsBadge(annual: annual.price, monthly: monthly.price)
            )
        }
        return Self.fallbackPaywallPrices(language: language)
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
        PaywallPriceDisplay(
            yearlyPrice: AppLocalizable.string("paywall.plan.fallback.yearlyPrice", language: language),
            yearlyPerMonth: AppLocalizable.string("paywall.plan.fallback.yearlyMonthly", language: language),
            monthlyPrice: AppLocalizable.string("paywall.plan.fallback.monthlyPrice", language: language),
            discountBadge: AppLocalizable.string("paywall.plan.discount", language: language)
        )
    }
}
