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
        offerings?.offering(identifier: "special_promo")?.package(identifier: "$rc_annual")
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
