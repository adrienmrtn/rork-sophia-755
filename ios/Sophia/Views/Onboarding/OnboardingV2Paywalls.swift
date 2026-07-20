import SwiftUI
import RevenueCat

/// Fonctionnalités comparées Free vs Pro (paywall comparatif).
private let ov2PaywallFeatureKeys = [
    "onboardingV2.pw.feature.allSubjects",
    "onboardingV2.pw.feature.unlimited",
    "onboardingV2.pw.feature.quiz",
    "onboardingV2.pw.feature.favorites",
    "onboardingV2.pw.feature.noAds",
    "onboardingV2.pw.feature.weekly",
]

// MARK: - Page 13 : paywall annuel (essai 3 jours)

/// Paywall natif, offering `fin_onboarding`, plan annuel uniquement.
/// Fermer (X) ou « Voir tous les plans » → paywall comparatif (page 14).
struct OnboardingV2PaywallAnnual: View {
    @Environment(LanguageManager.self) private var languageManager
    let store: StoreViewModel
    let onSubscribed: () -> Void
    let onClose: () -> Void

    @State private var purchasing = false
    @State private var appeared = false

    private var prices: StoreViewModel.PaywallPriceDisplay {
        store.paywallPriceDisplay(language: languageManager.current)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                closeButton
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(OV2.accent)

                headline
                    .padding(.horizontal, 28)

                Button(languageManager.text("onboardingV2.pw.viewAllPlans")) {
                    OnboardingHaptics.selection()
                    onClose()
                }
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(OV2.accentSoft)
            }
            .ov2Reveal(delay: 0.1)

            Spacer()

            VStack(spacing: 10) {
                Text(languageManager.text("onboardingV2.pw.twoTaps"))
                    .font(DS.sans(.footnote, .medium))
                    .foregroundStyle(OV2.inkSecondary)

                OnboardingV2Button(
                    title: purchasing
                        ? languageManager.text("common.processing")
                        : languageManager.text("onboardingV2.pw.startTrial"),
                    enabled: !purchasing,
                    action: purchase
                )

                legalRow.padding(.bottom, 12)
            }
        }
        .ov2Background()
    }

    private var headline: some View {
        let green = languageManager.text("onboardingV2.pw.tryFree")
        let rest = String(
            format: languageManager.text("onboardingV2.pw.thenPrice"),
            prices.yearlyPerMonth, prices.yearlyPrice
        )
        return (
            Text(green + " ").font(DS.title(.title2, .heavy)).foregroundColor(OV2.success)
            + Text(rest).font(DS.title(.title2, .heavy)).foregroundColor(OV2.ink)
        )
        .multilineTextAlignment(.center)
    }

    private var closeButton: some View {
        Button {
            OnboardingHaptics.selection()
            onClose()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(OV2.inkTertiary)
                .frame(width: 40, height: 40)
        }
    }

    private var legalRow: some View {
        OnboardingV2LegalRow(onRestore: { Task { await store.restore() } })
    }

    private func purchase() {
        guard let package = store.annualPackage, !purchasing else { return }
        purchasing = true
        Task {
            let ok = await store.purchase(package: package)
            purchasing = false
            if ok {
                AnalyticsService.trackPurchaseCompleted(
                    context: SophiaPaywallContext.finOnboarding.rawValue,
                    offeringId: store.offerings?.current?.identifier,
                    packageId: package.identifier
                )
                onSubscribed()
            }
        }
    }
}

// MARK: - Page 14 : paywall comparatif (annuel vs mensuel)

/// Paywall natif comparatif. Fermer (X) → freemium (fin d'onboarding).
struct OnboardingV2PaywallComparison: View {
    @Environment(LanguageManager.self) private var languageManager
    let store: StoreViewModel
    let onSubscribed: () -> Void
    let onClose: () -> Void

    enum Plan { case yearly, monthly }
    @State private var selected: Plan = .yearly
    @State private var purchasing = false

    private var prices: StoreViewModel.PaywallPriceDisplay {
        store.paywallPriceDisplay(language: languageManager.current)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                closeButton
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text(languageManager.text("onboardingV2.pw.compare.title"))
                        .font(DS.title(.title, .heavy))
                        .foregroundStyle(OV2.ink)
                        .padding(.top, 4)

                    comparisonTable
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }

            VStack(spacing: 10) {
                planCard(.yearly)
                planCard(.monthly)

                OnboardingV2Button(
                    title: purchasing
                        ? languageManager.text("common.processing")
                        : languageManager.text("onboardingV2.pw.startTrial"),
                    enabled: !purchasing,
                    action: purchase
                )

                OnboardingV2LegalRow(onRestore: { Task { await store.restore() } })
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
        .ov2Background()
    }

    private var comparisonTable: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(languageManager.text("onboardingV2.pw.free"))
                    .font(DS.sans(.caption, .semibold)).foregroundStyle(OV2.inkSecondary)
                    .frame(width: 54)
                Text("PRO")
                    .font(DS.sans(.caption, .bold)).foregroundStyle(.white)
                    .frame(width: 54, height: 22)
                    .background(OV2.accent, in: Capsule())
            }
            .padding(.bottom, 8)

            ForEach(ov2PaywallFeatureKeys, id: \.self) { key in
                HStack {
                    Text(languageManager.text(key))
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(OV2.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(OV2.inkTertiary)
                        .frame(width: 54)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(OV2.accent)
                        .frame(width: 54)
                }
                .padding(.vertical, 10)
                Divider().overlay(OV2.hairline)
            }
        }
    }

    private func planCard(_ plan: Plan) -> some View {
        let isSelected = selected == plan
        let isYearly = plan == .yearly
        return Button {
            OnboardingHaptics.planSelected()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) { selected = plan }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(isYearly ? languageManager.text("onboardingV2.pw.yearly") : languageManager.text("onboardingV2.pw.monthly"))
                        .font(DS.sans(.body, .bold))
                        .foregroundStyle(OV2.ink)
                    Text(isYearly ? prices.yearlyPerMonth : languageManager.text("onboardingV2.pw.monthlyBilling"))
                        .font(DS.sans(.caption, .medium))
                        .foregroundStyle(OV2.inkSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(isYearly ? prices.yearlyPrice : prices.monthlyPrice)
                        .font(DS.sans(.body, .bold))
                        .foregroundStyle(OV2.ink)
                    if isYearly {
                        Text(languageManager.text("onboardingV2.pw.trialBadge"))
                            .font(DS.sans(.caption2, .bold))
                            .foregroundStyle(OV2.success)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .fill(isSelected ? OV2.accentSoft.opacity(0.08) : OV2.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(isSelected ? OV2.accent : OV2.hairline, lineWidth: isSelected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if isYearly, let badge = prices.discountBadge {
                    Text(String(format: languageManager.text("onboardingV2.pw.save"), badge))
                        .font(DS.sans(.caption2, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(OV2.accent, in: Capsule())
                        .offset(x: -12, y: -10)
                }
            }
        }
        .buttonStyle(SoftPressButtonStyle())
    }

    private var closeButton: some View {
        Button {
            OnboardingHaptics.selection()
            onClose()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(OV2.inkTertiary)
                .frame(width: 40, height: 40)
        }
    }

    private func purchase() {
        let package = selected == .yearly ? store.annualPackage : store.monthlyPackage
        guard let package, !purchasing else { return }
        purchasing = true
        Task {
            let ok = await store.purchase(package: package)
            purchasing = false
            if ok {
                AnalyticsService.trackPurchaseCompleted(
                    context: SophiaPaywallContext.finOnboarding.rawValue,
                    offeringId: store.offerings?.current?.identifier,
                    packageId: package.identifier
                )
                onSubscribed()
            }
        }
    }
}

// MARK: - Legal row partagée

struct OnboardingV2LegalRow: View {
    @Environment(LanguageManager.self) private var languageManager
    var onRestore: () -> Void
    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        HStack(spacing: 6) {
            Button(languageManager.text("paywall.restore"), action: onRestore)
            Text("·").foregroundStyle(OV2.inkTertiary)
            Button(languageManager.text("settings.terms.title")) { showTerms = true }
            Text("·").foregroundStyle(OV2.inkTertiary)
            Button(languageManager.text("settings.privacy.title")) { showPrivacy = true }
        }
        .font(DS.sans(.caption2, .medium))
        .foregroundStyle(OV2.inkTertiary)
        .sheet(isPresented: $showTerms) { TermsView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }
}
