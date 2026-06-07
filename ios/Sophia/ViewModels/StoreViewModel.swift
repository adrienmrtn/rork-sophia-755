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

    // MARK: - Onboarding paywall

    private static let onboardingOfferingIDs = ["fin_onboarding", "default"]

    /// Offering used by the native onboarding paywall — prefers `fin_onboarding`, then `default`, then RC current.
    var onboardingOffering: Offering? {
        guard let offerings else { return nil }
        for id in Self.onboardingOfferingIDs {
            if let offering = offerings.offering(identifier: id) ?? offerings.all[id] {
                return offering
            }
        }
        return offerings.current
    }

    var onboardingMonthlyPackage: Package? {
        onboardingOffering?.package(identifier: "$rc_monthly") ?? onboardingOffering?.monthly
    }

    var onboardingAnnualPackage: Package? {
        onboardingOffering?.package(identifier: "$rc_annual") ?? onboardingOffering?.annual
    }

    func onboardingPackage(forAnnual annual: Bool) -> Package? {
        annual ? onboardingAnnualPackage : onboardingMonthlyPackage
    }

    func hasIntroductoryOffer(for package: Package?) -> Bool {
        package?.storeProduct.introductoryDiscount != nil
    }

    /// Logs which offering/packages resolve and whether StoreKit reports an intro offer (for trial diagnostics).
    func logOnboardingPurchaseDiagnostics() {
        guard let offerings else {
            print("[OnboardingPaywall] offerings is nil — fetchOfferings may have failed: \(error ?? "unknown")")
            return
        }

        let available = offerings.all.keys.sorted().joined(separator: ", ")
        print("[OnboardingPaywall] RC offerings available: [\(available)] — current: \(offerings.current?.identifier ?? "nil")")

        guard let offering = onboardingOffering else {
            print("[OnboardingPaywall] no onboarding offering resolved")
            return
        }

        print("[OnboardingPaywall] using offering: \(offering.identifier)")

        for (label, package) in [("annual", onboardingAnnualPackage), ("monthly", onboardingMonthlyPackage)] {
            guard let package else {
                print("[OnboardingPaywall] \(label) package missing in offering '\(offering.identifier)'")
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
}
