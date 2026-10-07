import SwiftUI
import RevenueCat

/// Fonctionnalités comparées Free vs Pro (paywall comparatif).
/// The comparison rows, and whether the free plan has each one. This is the real freemium
/// rule (`FreemiumGate`): free readers already have every subject and unlimited favourites;
/// what they do not have is more than one course a day, the quizzes, the audio mode and
/// the TikTok blocker.
private struct OV2PaywallFeature {
    let key: String
    let free: Bool
}

private let ov2PaywallFeatures: [OV2PaywallFeature] = [
    .init(key: "onboardingV2.pw.feature.allSubjects", free: true),
    .init(key: "onboardingV2.pw.feature.favorites", free: true),
    .init(key: "onboardingV2.pw.feature.unlimited", free: false),
    .init(key: "onboardingV2.pw.feature.quiz", free: false),
    .init(key: "onboardingV2.pw.feature.audio", free: false),
    .init(key: "onboardingV2.pw.feature.tiktokBlocker", free: false),
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
    @State private var didReloadOfferings = false
    @State private var appeared = false
    @State private var photos: [UIImage] = []

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

                socialProofRow

                Button(languageManager.text("onboardingV2.pw.viewAllPlans")) {
                    OnboardingHaptics.selection()
                    onClose()
                }
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(OV2.accentSoft)
            }
            .ov2Reveal(delay: 0.1)

            Spacer()

            // Le bouton descend au plus près du bas : la note de prix est collée dessous,
            // puis la ligne légale, sans marge inutile entre les trois.
            VStack(spacing: 0) {
                Text(languageManager.text("onboardingV2.pw.twoTaps"))
                    .font(DS.sans(.footnote, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .padding(.bottom, 10)

                OnboardingV2Button(
                    title: purchasing
                        ? languageManager.text("common.processing")
                        : languageManager.trialText("onboardingV2.pw.startTrial", days: store.annualTrialDays),
                    enabled: !purchasing,
                    bottomPadding: 8,
                    action: purchase
                )

                // The amount the store actually charges, small and grey, right under the
                // button: "(facturé 39,99 € par an)".
                if !prices.yearlyBilledNote.isEmpty {
                    Text("(\(prices.yearlyBilledNote))")
                        .font(DS.sans(.footnote, .medium))
                        .foregroundStyle(OV2.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                }

                legalRow.padding(.bottom, 10)
            }
        }
        .ov2Background()
        .onAppear {
            store.trackPaywallImpression(paywallId: "onboarding_annual")
            if photos.isEmpty { photos = Array(OnboardingStudentPhotos.load().prefix(3)) }
        }
    }

    /// Preuve sociale discrète : trois visages, la note et le nombre d'utilisateurs, sur
    /// une ligne, sous la promesse d'essai.
    private var socialProofRow: some View {
        HStack(spacing: 10) {
            if !photos.isEmpty {
                OnboardingV2PhotoRow(photos: photos, size: 28)
            }
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(OV2.warm)
                Text((4.8).formatted(.number.precision(.fractionLength(1)).locale(languageManager.locale)))
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(OV2.ink)
                Text("· " + languageManager.text("onboardingV2.loading.social.count"))
                    .font(DS.sans(.footnote, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// "Essaie 3 jours gratuitement, puis 3,33 € / mois (facturé annuellement)." — the free
    /// days in green, then the monthly equivalent. Always worded with the trial: every annual
    /// plan of the catalogue carries one, and a store that has not served the intro offer yet
    /// (sandbox, offer pending review) used to make the page read "Premium à 3,33 € / mois"
    /// (decision of 29/09/2026). The day count still follows the served product.
    private var headline: some View {
        let green = languageManager.trialText("onboardingV2.pw.tryFree", days: store.annualTrialDays)
        let rest = String(format: languageManager.text("onboardingV2.pw.thenPrice"), prices.yearlyPerMonth)
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
        guard !purchasing else { return }
        // Offres pas encore chargées (réseau lent au lancement) : on les recharge au lieu de
        // laisser un bouton qui ne fait rien, puis on relance l'achat.
        guard let package = store.annualPackage else { reloadOfferingsThenPurchase(); return }
        purchasing = true
        Task {
            let ok = await store.purchase(package: package)
            purchasing = false
            if ok {
                onSubscribed()
            }
        }
    }

    /// Recharge les offres puis relance l'achat. Une seule fois : sans cette garde, un
    /// rechargement qui n'aboutit pas relancerait `purchase()`, qui rappellerait ce
    /// rechargement, en boucle. Le bouton retrouve donc toujours son état normal — et le X
    /// de fermeture, lui, reste actif en permanence.
    private func reloadOfferingsThenPurchase() {
        guard !didReloadOfferings else { return }
        didReloadOfferings = true
        purchasing = true
        Task {
            await store.loadOfferingsWithRetry()
            purchasing = false
            purchase()
        }
    }
}

// MARK: - Page 14 : paywall comparatif (annuel vs plan court : mensuel ou hebdo)

/// Paywall natif comparatif. Fermer (X) → freemium (fin d'onboarding).
struct OnboardingV2PaywallComparison: View {
    @Environment(LanguageManager.self) private var languageManager
    let store: StoreViewModel
    let onSubscribed: () -> Void
    let onClose: () -> Void

    enum Plan { case yearly, short }
    @State private var selected: Plan = .yearly
    @State private var purchasing = false
    @State private var didReloadOfferings = false

    private var prices: StoreViewModel.PaywallPriceDisplay {
        store.paywallPriceDisplay(language: languageManager.current)
    }

    /// Trial availability is per product, so each plan card is checked independently: an
    /// experiment can remove the intro offer from one plan only.
    private var yearlyHasTrial: Bool { store.hasFreeTrial(store.annualPackage) }
    private var shortHasTrial: Bool { store.hasFreeTrial(store.shortPlanPackage) }
    /// The short plan is monthly unless the served offering carries a weekly package.
    private var shortIsWeekly: Bool { prices.shortPlanIsWeekly }

    private var selectedHasTrial: Bool {
        selected == .yearly ? yearlyHasTrial : shortHasTrial
    }

    private func trialDays(_ plan: Plan) -> Int {
        store.trialDays(for: plan == .yearly ? store.annualPackage : store.shortPlanPackage) ?? 3
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
                // De l'air entre le tableau et le choix des plans.
                .padding(.bottom, 30)
            }

            VStack(spacing: 10) {
                planCard(.yearly)
                planCard(.short)

                OnboardingV2Button(
                    title: purchasing
                        ? languageManager.text("common.processing")
                        : (selectedHasTrial
                            ? languageManager.trialText("onboardingV2.pw.startTrial", days: trialDays(selected))
                            : languageManager.text("onboardingV2.pw.subscribe")),
                    enabled: !purchasing,
                    bottomPadding: 10,
                    action: purchase
                )

                OnboardingV2LegalRow(onRestore: { Task { await store.restore() } })
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
        }
        .ov2Background()
        .onAppear {
            store.trackPaywallImpression(paywallId: "onboarding_comparison")
        }
    }

    /// Free / PRO column width — room for TR/HU/BG free labels with scale, still aligned for icons.
    private var comparisonColumnWidth: CGFloat { 72 }
    private static let rowHeight: CGFloat = 46

    /// Le tableau dans une carte ; la colonne PRO est une bande teintée, couronnée, avec des
    /// coches pleines, face à une colonne Gratuit en gris : l'œil va tout de suite à PRO.
    private var comparisonTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Text(languageManager.text("onboardingV2.pw.free"))
                    .font(DS.sans(.caption, .semibold)).foregroundStyle(OV2.inkTertiary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.center)
                    .frame(width: comparisonColumnWidth)
                VStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(OV2.warm)
                    Text(languageManager.text("onboardingV2.pw.pro"))
                        .font(DS.sans(.caption, .heavy)).foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 10)
                        .frame(minWidth: 52, minHeight: 24)
                        .background(OV2.accent, in: Capsule())
                }
                .frame(width: comparisonColumnWidth)
            }
            .frame(height: 64)

            ForEach(Array(ov2PaywallFeatures.enumerated()), id: \.element.key) { index, feature in
                if index > 0 {
                    Divider().overlay(OV2.hairline)
                }
                HStack(spacing: 0) {
                    Text(languageManager.text(feature.key))
                        .font(DS.sans(.subheadline, .semibold))
                        .foregroundStyle(OV2.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Group {
                        if feature.free {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(OV2.inkTertiary)
                        } else {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(OV2.inkTertiary.opacity(0.6))
                        }
                    }
                    .frame(width: comparisonColumnWidth)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white, OV2.accent)
                        .frame(width: comparisonColumnWidth)
                }
                .frame(minHeight: Self.rowHeight)
            }
        }
        .padding(.leading, 16)
        .background(alignment: .trailing) {
            // La bande PRO, du haut en bas de la carte.
            LinearGradient(
                colors: [OV2.accent.opacity(0.14), OV2.accentSoft.opacity(0.05)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(width: comparisonColumnWidth)
            .overlay(alignment: .leading) {
                Rectangle().fill(OV2.accent.opacity(0.18)).frame(width: 1)
            }
        }
        .background(OV2.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(OV2.hairline, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
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
                    Text(isYearly
                         ? languageManager.text("onboardingV2.pw.yearly")
                         : languageManager.text(shortIsWeekly ? "onboardingV2.pw.weekly" : "onboardingV2.pw.monthly"))
                        .font(DS.sans(.body, .bold))
                        .foregroundStyle(OV2.ink)
                    // Le prix affiché en gros est dans l'unité du plan court des deux côtés
                    // (par mois, ou par semaine face à un plan hebdo), pour comparer les deux
                    // plans dans la même unité. Le montant réellement prélevé reste sous le
                    // nom du plan, en petit : « facturé 39,99 € par an ».
                    Text(isYearly
                         ? prices.yearlyBilledNote
                         : languageManager.text(shortIsWeekly ? "onboardingV2.pw.weeklyBilling" : "onboardingV2.pw.monthlyBilling"))
                        .font(DS.sans(.caption, .medium))
                        .foregroundStyle(OV2.inkSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    // Les deux plans dans la même unité : « 3,33 € / mois » face à « 9,99 € / mois ».
                    Text(isYearly ? prices.yearlyPerShortPeriod : shortPlanPriceWithPeriod)
                        .font(DS.sans(.body, .bold))
                        .foregroundStyle(OV2.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if isYearly ? yearlyHasTrial : shortHasTrial {
                        Text(languageManager.trialText("onboardingV2.pw.trialBadge", days: trialDays(plan)))
                            .font(DS.sans(.caption2, .bold))
                            .foregroundStyle(OV2.success)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
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
                    // "-58%" is a badge; "Économise -58 %" would read as a double negative.
                    Text(String(format: languageManager.text("onboardingV2.pw.save"), badge.trimmingCharacters(in: CharacterSet(charactersIn: "-"))))
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

    /// « 9,99 € / mois » (ou « / semaine ») : le prix du plan court avec son unité.
    private var shortPlanPriceWithPeriod: String {
        prices.shortPlanPrice + " " + languageManager.text(shortIsWeekly ? "paywall.plan.perWeek" : "paywall.plan.perMonth")
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
        guard !purchasing else { return }
        let selectedPackage = selected == .yearly ? store.annualPackage : store.shortPlanPackage
        // Offres pas encore chargées (réseau lent au lancement) : on les recharge au lieu de
        // laisser un bouton qui ne fait rien, puis on relance l'achat.
        guard let package = selectedPackage else { reloadOfferingsThenPurchase(); return }
        purchasing = true
        Task {
            let ok = await store.purchase(package: package)
            purchasing = false
            if ok {
                onSubscribed()
            }
        }
    }

    /// Recharge les offres puis relance l'achat. Une seule fois : sans cette garde, un
    /// rechargement qui n'aboutit pas relancerait `purchase()`, qui rappellerait ce
    /// rechargement, en boucle. Le bouton retrouve donc toujours son état normal — et le X
    /// de fermeture, lui, reste actif en permanence.
    private func reloadOfferingsThenPurchase() {
        guard !didReloadOfferings else { return }
        didReloadOfferings = true
        purchasing = true
        Task {
            await store.loadOfferingsWithRetry()
            purchasing = false
            purchase()
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
        // DE/PT legal strings overflow a single HStack on narrow phones — wrap when needed.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) { legalButtons }
            VStack(spacing: 4) {
                Button(languageManager.text("paywall.restore"), action: onRestore)
                HStack(spacing: 6) {
                    Button(languageManager.text("settings.terms.title")) { showTerms = true }
                    Text("·").foregroundStyle(OV2.inkTertiary)
                    Button(languageManager.text("settings.privacy.title")) { showPrivacy = true }
                }
            }
        }
        .font(DS.sans(.caption2, .medium))
        .foregroundStyle(OV2.inkTertiary)
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.85)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showTerms) { TermsView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }

    @ViewBuilder
    private var legalButtons: some View {
        Button(languageManager.text("paywall.restore"), action: onRestore)
        Text("·").foregroundStyle(OV2.inkTertiary)
        Button(languageManager.text("settings.terms.title")) { showTerms = true }
        Text("·").foregroundStyle(OV2.inkTertiary)
        Button(languageManager.text("settings.privacy.title")) { showPrivacy = true }
    }
}
