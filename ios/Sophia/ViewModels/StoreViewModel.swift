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
}
