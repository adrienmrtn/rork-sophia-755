import SwiftUI
import RevenueCat

struct OnboardingNativePaywallView: View {
    @Environment(LanguageManager.self) private var languageManager

    enum Plan: String, CaseIterable, Identifiable {
        case yearly
        case monthly
        var id: String { rawValue }
    }

    var store: StoreViewModel
    let onPurchase: (Plan) -> Void
    let onRestore: () -> Void
    let onClose: () -> Void

    @State private var selectedPlan: Plan = .yearly
    @State private var showReminderSheet: Bool = false
    @State private var showLegalSafari: Bool = false

    private let legalURL = URL(string: "https://vikstudios.com/sophia")!
    private let benefits = PaywallBenefitItem.figmaItems()

    private var unlockedSubjects: Set<Subject> {
        FreemiumGate.unlockedSubjects(isPremium: false)
    }

    private var lockedSubjects: [Subject] {
        Subject.allCases.filter { !unlockedSubjects.contains($0) }
    }

    private var prices: StoreViewModel.PaywallPriceDisplay {
        store.paywallPriceDisplay(language: paywallLanguage)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width

            ZStack(alignment: .topTrailing) {
                PaywallDesign.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        paywallContent(width: w)
                    }

                    footer(width: w)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Spacer()
                    closeButton
                }
                .padding(.horizontal, PaywallDesign.s(16, width: w))
                .padding(.top, PaywallDesign.s(8, width: w))
            }
        }
        .onAppear {
            PaywallFonts.registerIfNeeded()
            store.logOnboardingPurchaseDiagnostics()
        }
        .sheet(isPresented: $showReminderSheet) {
            PaywallTrialTimelineSheet(
                onContinue: {
                    showReminderSheet = false
                    onPurchase(selectedPlan)
                }
            )
            .presentationDetents([.fraction(0.68)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showLegalSafari) {
            InAppSafariView(url: legalURL)
                .ignoresSafeArea()
        }
    }

    // MARK: - Scroll content

    @ViewBuilder
    private func paywallContent(width w: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection(width: w)
            sectionGap(PaywallSpacing.afterHeader, width: w)

            subjectsSection(width: w)
            sectionGap(PaywallSpacing.afterSubjects, width: w)

            weaponSection(width: w)
            sectionGap(PaywallSpacing.afterWeapon, width: w)

            benefitsSection(width: w)
            sectionGap(PaywallSpacing.afterBenefits, width: w)

            premiumHeadlineSection(width: w)
            sectionGap(PaywallSpacing.afterPremiumHeadline, width: w)

            featureComparison(width: w)
            sectionGap(PaywallSpacing.afterTable, width: w)

            plansSection(width: w)
            sectionGap(PaywallSpacing.afterPlans, width: w)

            legalRow(width: w)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, PaywallDesign.s(PaywallSpacing.horizontal, width: w))
        .padding(.top, PaywallDesign.s(12, width: w))
        .padding(.bottom, PaywallDesign.s(24, width: w))
    }

    private func sectionGap(_ value: CGFloat, width w: CGFloat) -> some View {
        Color.clear.frame(height: PaywallDesign.s(value, width: w))
    }

    // MARK: - Header

    private func headerSection(width w: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            PaywallHighlightedHeadline(
                text: fr("paywall.header"),
                highlight: fr("paywall.header.highlight"),
                fontSize: 34.071,
                lineHeight: 37.965,
                highlightColor: PaywallDesign.highlightYellow,
                layoutWidth: w
            )
            .frame(maxWidth: PaywallDesign.s(PaywallSpacing.headlineMaxWidth, width: w), alignment: .leading)

            HStack(alignment: .top, spacing: 0) {
                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: PaywallDesign.s(11, width: w)) {
                    HStack(spacing: PaywallDesign.s(4, width: w)) {
                        figmaStar("paywall_star_1", size: CGSize(width: 15, height: 14), width: w)
                        figmaStar("paywall_star_2", size: CGSize(width: 9, height: 8), width: w)
                    }

                    Image("paywall_lightbulb")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: PaywallDesign.s(73, width: w),
                            height: PaywallDesign.s(91, width: w)
                        )
                        .rotationEffect(.degrees(15.61))
                }
                .offset(y: PaywallDesign.s(8, width: w))
            }
        }
    }

    // MARK: - Subjects

    private func subjectsSection(width w: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            subjectsCard(width: w)
                .rotationEffect(.degrees(-1.98))
                .padding(.leading, PaywallDesign.s(28, width: w))
                .padding(.trailing, PaywallDesign.s(8, width: w))
                .padding(.vertical, PaywallDesign.s(12, width: w))

            Image("paywall_pencil")
                .resizable()
                .scaledToFit()
                .frame(
                    width: PaywallDesign.s(142, width: w),
                    height: PaywallDesign.s(104, width: w)
                )
                .rotationEffect(.degrees(-178.83))
                .offset(x: PaywallDesign.s(-8, width: w), y: PaywallDesign.s(18, width: w))

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    figmaStar("paywall_star_3", size: CGSize(width: 15, height: 13), width: w)
                        .offset(x: PaywallDesign.s(-120, width: w), y: PaywallDesign.s(-8, width: w))
                    figmaStar("paywall_star_4", size: CGSize(width: 8, height: 9), width: w)
                        .offset(x: PaywallDesign.s(-132, width: w), y: PaywallDesign.s(-28, width: w))
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func subjectsCard(width w: CGFloat) -> some View {
        let corner = PaywallDesign.s(15, width: w)

        return VStack(alignment: .leading, spacing: PaywallDesign.s(14, width: w)) {
            Text(fr("paywall.freeSubjects"))
                .font(PaywallDesign.quicksandBold(15, width: w))
                .foregroundStyle(BrutalPalette.ink)

            FlowLayout(spacing: PaywallDesign.s(10, width: w)) {
                ForEach(Array(unlockedSubjects).sorted(by: subjectSort), id: \.self) { subject in
                    subjectPill(subject, locked: false, width: w)
                }
            }

            Text(fr("paywall.lockedSubjectsWithPremium"))
                .font(PaywallDesign.quicksandBold(15, width: w))
                .foregroundStyle(BrutalPalette.ink.opacity(0.4))
                .padding(.top, PaywallDesign.s(4, width: w))

            FlowLayout(spacing: PaywallDesign.s(12, width: w)) {
                ForEach(lockedSubjects, id: \.self) { subject in
                    subjectPill(subject, locked: true, width: w)
                }
            }
            .opacity(0.4)
        }
        .padding(PaywallDesign.s(18, width: w))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
        .paywallFigmaShadow(corner: corner, depth: PaywallDesign.s(3, width: w))
    }

    // MARK: - Weapon + benefits

    private func weaponSection(width w: CGFloat) -> some View {
        ZStack(alignment: .topTrailing) {
            PaywallHighlightedHeadline(
                text: fr("paywall.weaponHeadline"),
                highlight: fr("paywall.weaponHeadline.highlight"),
                fontSize: 34.071,
                lineHeight: 37.965,
                highlightColor: PaywallDesign.highlightPink,
                layoutWidth: w
            )
            .frame(maxWidth: PaywallDesign.s(PaywallSpacing.headlineMaxWidth, width: w), alignment: .leading)
            .padding(.trailing, PaywallDesign.s(72, width: w))

            VStack(alignment: .trailing, spacing: PaywallDesign.s(8, width: w)) {
                HStack(spacing: PaywallDesign.s(4, width: w)) {
                    figmaStar("paywall_star_5", size: CGSize(width: 9, height: 9), width: w)
                    figmaStar("paywall_star_6", size: CGSize(width: 6, height: 6), width: w)
                }

                Image("paywall_phi")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: PaywallDesign.s(74, width: w),
                        height: PaywallDesign.s(87, width: w)
                    )
                    .rotationEffect(.degrees(-9.06))
            }
            .offset(y: PaywallDesign.s(4, width: w))
        }
    }

    private func benefitsSection(width w: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: PaywallDesign.s(PaywallSpacing.betweenBenefits, width: w)) {
            ForEach(benefits) { benefit in
                benefitCard(benefit, width: w)
            }
        }
    }

    private func benefitCard(_ benefit: PaywallBenefitItem, width w: CGFloat) -> some View {
        let corner = PaywallDesign.s(13, width: w)

        return HStack(spacing: 0) {
            Color.clear.frame(width: PaywallDesign.s(benefit.leadingInset, width: w))

            Text(fr(benefit.textKey))
                .font(PaywallDesign.quicksandBold(13.67, width: w))
                .foregroundStyle(BrutalPalette.ink)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, PaywallDesign.s(20, width: w))
                .padding(.vertical, PaywallDesign.s(14, width: w))
                .background(benefit.color, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
                .paywallFigmaShadow(
                    corner: corner,
                    depth: PaywallDesign.s(2, width: w),
                    borderWidth: PaywallDesign.s(1.5, width: w)
                )
                .rotationEffect(.degrees(benefit.rotation))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Premium headline + table

    private func premiumHeadlineSection(width w: CGFloat) -> some View {
        PaywallHighlightedHeadline(
            text: fr("paywall.premiumHeadline"),
            highlight: fr("paywall.premiumHeadline.highlight"),
            fontSize: 34,
            lineHeight: 38,
            highlightColor: PaywallDesign.highlightYellow,
            layoutWidth: w
        )
        .frame(maxWidth: PaywallDesign.s(PaywallSpacing.headlineMaxWidth, width: w), alignment: .leading)
    }

    private func featureComparison(width w: CGFloat) -> some View {
        let corner = PaywallDesign.s(17, width: w)
        let premiumColumnWidth = PaywallDesign.s(82, width: w)

        return VStack(spacing: 0) {
            HStack {
                Text(fr("paywall.featureColumn"))
                    .font(PaywallDesign.quicksandBold(9.243, width: w))
                    .foregroundStyle(BrutalPalette.ink)
                Spacer()
                Text(fr("paywall.freeColumn"))
                    .font(PaywallDesign.quicksandBold(9.243, width: w))
                    .foregroundStyle(BrutalPalette.ink)
                    .frame(width: PaywallDesign.s(52, width: w))
                Text(fr("paywall.premiumColumn"))
                    .font(PaywallDesign.quicksandBold(9.243, width: w))
                    .foregroundStyle(BrutalPalette.ink)
                    .frame(width: PaywallDesign.s(72, width: w))
            }
            .padding(.horizontal, PaywallDesign.s(16, width: w))
            .padding(.vertical, PaywallDesign.s(14, width: w))

            featureRow(fr("paywall.feature.3subjects"), freeIcon: "paywall_free_3matieres", premiumIcon: "paywall_check_premium", width: w)
            featureRow(fr("paywall.feature.allSubjects"), freeIcon: "paywall_free_toutes", premiumIcon: "paywall_check_premium", width: w)
            featureRow(fr("paywall.feature.unlimitedCourses"), freeIcon: "paywall_free_cours", premiumIcon: "paywall_check_premium", width: w)
            featureRow(fr("paywall.feature.miniQuiz"), freeIcon: "paywall_free_quiz", premiumIcon: "paywall_check_premium", width: w)
            featureRow(fr("paywall.feature.fullLibrary"), freeIcon: "paywall_free_biblio", premiumIcon: "paywall_check_premium", width: w)
        }
        .background(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: PaywallDesign.s(14, width: w), style: .continuous)
                .fill(PaywallDesign.creamHighlight)
                .overlay {
                    RoundedRectangle(cornerRadius: PaywallDesign.s(14, width: w), style: .continuous)
                        .strokeBorder(PaywallDesign.orange, lineWidth: PaywallDesign.s(2, width: w))
                }
                .frame(width: premiumColumnWidth)
                .padding(.top, PaywallDesign.s(10, width: w))
                .padding(.bottom, PaywallDesign.s(10, width: w))
                .padding(.trailing, PaywallDesign.s(10, width: w))
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
        .paywallFigmaShadow(corner: corner, depth: PaywallDesign.s(3, width: w))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func featureRow(_ title: String, freeIcon: String, premiumIcon: String, width w: CGFloat) -> some View {
        HStack(spacing: PaywallDesign.s(8, width: w)) {
            Text(title)
                .font(PaywallDesign.quicksandBold(12.65, width: w))
                .foregroundStyle(BrutalPalette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(freeIcon)
                .resizable()
                .scaledToFit()
                .frame(width: PaywallDesign.s(22.323, width: w), height: PaywallDesign.s(22.323, width: w))
                .frame(width: PaywallDesign.s(52, width: w))
            Image(premiumIcon)
                .resizable()
                .scaledToFit()
                .frame(width: PaywallDesign.s(22.323, width: w), height: PaywallDesign.s(22.323, width: w))
                .frame(width: PaywallDesign.s(72, width: w))
        }
        .padding(.horizontal, PaywallDesign.s(16, width: w))
        .padding(.vertical, PaywallDesign.s(9, width: w))
    }

    // MARK: - Plans

    private func plansSection(width w: CGFloat) -> some View {
        VStack(spacing: PaywallDesign.s(PaywallSpacing.betweenPlans, width: w)) {
            planCard(.yearly, width: w)
            planCard(.monthly, width: w)
        }
    }

    @ViewBuilder
    private func planCard(_ plan: Plan, width w: CGFloat) -> some View {
        let isSelected = selectedPlan == plan
        let isYearly = plan == .yearly
        let faded = !isSelected
        let corner = PaywallDesign.s(13, width: w)

        Button {
            OnboardingHaptics.planSelected()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedPlan = plan
            }
        } label: {
            VStack(spacing: 0) {
                Text(fr("paywall.trialBadge"))
                    .font(PaywallDesign.nunitoExtraBold(11.607, width: w))
                    .foregroundStyle(BrutalPalette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PaywallDesign.s(8, width: w))
                    .background(
                        isYearly
                            ? PaywallDesign.orange
                            : PaywallDesign.orange.opacity(faded ? 0.4 : 1)
                    )

                HStack(spacing: PaywallDesign.s(14, width: w)) {
                    PaywallSquareCheckbox(isSelected: isSelected, layoutWidth: w, faded: faded)

                    VStack(alignment: .leading, spacing: PaywallDesign.s(4, width: w)) {
                        Text(isYearly ? fr("paywall.plan.yearly") : fr("paywall.plan.monthly"))
                            .font(PaywallDesign.productSans(17, width: w))
                            .foregroundStyle(BrutalPalette.ink.opacity(faded ? 0.5 : 1))
                        Text(isYearly ? prices.yearlyPerMonth : fr("paywall.plan.monthlySubtitle"))
                            .font(PaywallDesign.quicksandSemiBold(11.051, width: w))
                            .foregroundStyle(BrutalPalette.ink.opacity(faded ? 0.35 : 0.6))
                    }

                    Spacer(minLength: PaywallDesign.s(8, width: w))

                    VStack(alignment: .trailing, spacing: PaywallDesign.s(4, width: w)) {
                        Text(isYearly ? prices.yearlyPrice : prices.monthlyPrice)
                            .font(PaywallDesign.productSans(17, width: w))
                            .foregroundStyle(BrutalPalette.ink.opacity(faded ? 0.5 : 1))
                        Text(isYearly ? fr("paywall.plan.perYear") : fr("paywall.plan.perMonth"))
                            .font(PaywallDesign.quicksandSemiBold(11.051, width: w))
                            .foregroundStyle(BrutalPalette.ink.opacity(faded ? 0.35 : 0.6))
                    }
                }
                .padding(.horizontal, PaywallDesign.s(16, width: w))
                .padding(.vertical, PaywallDesign.s(14, width: w))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isSelected && isYearly ? PaywallDesign.creamHighlight : Color.white)
            }
            .frame(maxWidth: .infinity)
            .paywallFigmaShadow(
                corner: corner,
                depth: PaywallDesign.s(3, width: w),
                shadowColor: BrutalPalette.ink.opacity(isSelected ? 1 : 0.3),
                borderColor: isSelected
                    ? (isYearly ? PaywallDesign.orange : BrutalPalette.ink)
                    : BrutalPalette.ink.opacity(0.3),
                borderWidth: PaywallDesign.s(2, width: w)
            )
            .overlay(alignment: .bottomTrailing) {
                if isYearly, selectedPlan == .yearly {
                    let badge = prices.discountBadge ?? fr("paywall.plan.discount")
                    Text(badge)
                        .font(PaywallDesign.nunitoExtraBold(13.595, width: w))
                        .foregroundStyle(BrutalPalette.ink)
                        .padding(.horizontal, PaywallDesign.s(10, width: w))
                        .padding(.vertical, PaywallDesign.s(6, width: w))
                        .background(PaywallDesign.accentPink, in: RoundedRectangle(cornerRadius: PaywallDesign.s(9, width: w), style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: PaywallDesign.s(9, width: w), style: .continuous)
                                .strokeBorder(BrutalPalette.ink, lineWidth: PaywallDesign.s(1.5, width: w))
                        }
                        .rotationEffect(.degrees(7))
                        .offset(x: PaywallDesign.s(6, width: w), y: PaywallDesign.s(10, width: w))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private func footer(width w: CGFloat) -> some View {
        VStack(spacing: PaywallDesign.s(8, width: w)) {
            Text(fr("paywall.cancelAnytime"))
                .font(PaywallDesign.quicksandSemiBold(12, width: w))
                .foregroundStyle(BrutalPalette.ink.opacity(0.5))

            OnboardingPrimaryButton(title: store.isPurchasing ? fr("common.processing") : fr("common.continue")) {
                guard !store.isPurchasing else { return }
                showReminderSheet = true
            }
            .disabled(store.isPurchasing)
        }
        .padding(.top, PaywallDesign.s(8, width: w))
        .background(
            PaywallDesign.background
                .frame(height: PaywallDesign.s(185, width: w))
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func legalRow(width w: CGFloat) -> some View {
        HStack(spacing: PaywallDesign.s(6, width: w)) {
            Button(fr("paywall.restore"), action: onRestore)
            Text("·")
            Button(fr("paywall.terms")) { showLegalSafari = true }
            Text("·")
            Button(fr("paywall.privacy")) { showLegalSafari = true }
        }
        .font(PaywallDesign.quicksandSemiBold(13, width: w))
        .foregroundStyle(BrutalPalette.ink.opacity(0.55))
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var closeButton: some View {
        Button {
            OnboardingHaptics.selection()
            onClose()
        } label: {
            Image("paywall_close")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 14)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(fr("common.close"))
    }

    // MARK: - Helpers

    private func figmaStar(_ name: String, size: CGSize, width w: CGFloat) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(
                width: PaywallDesign.s(size.width, width: w),
                height: PaywallDesign.s(size.height, width: w)
            )
    }

    private func subjectPill(_ subject: Subject, locked: Bool, width w: CGFloat) -> some View {
        let label = subject.localizedShortName(language: paywallLanguage)

        return Text(label)
            .font(PaywallDesign.quicksandSemiBold(10.614, width: w))
            .foregroundStyle(BrutalPalette.ink)
            .frame(height: PaywallDesign.s(22, width: w))
            .padding(.horizontal, PaywallDesign.s(14, width: w))
            .background(
                locked ? PaywallDesign.lockedPill : PaywallDesign.freePillColor(for: subject),
                in: Capsule()
            )
            .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: PaywallDesign.s(1.364, width: w)) }
            .shadow(color: BrutalPalette.ink, radius: 0, x: 0, y: PaywallDesign.s(0.909, width: w))
    }

    private var paywallLanguage: AppLanguage {
        languageManager.current
    }

    private func fr(_ key: String) -> String {
        AppLocalizable.string(key, language: paywallLanguage)
    }

    private func subjectSort(_ lhs: Subject, _ rhs: Subject) -> Bool {
        lhs.localizedShortName(language: paywallLanguage) < rhs.localizedShortName(language: paywallLanguage)
    }
}

// MARK: - Trial timeline sheet

private struct PaywallTrialTimelineSheet: View {
    @Environment(LanguageManager.self) private var languageManager

    let onContinue: () -> Void

    private let iconColumnWidth: CGFloat = 42
    private let rowSpacing: CGFloat = 18

    private var steps: [(icon: String, title: String, subtitle: String, detail: String)] {
        [
            ("lock.open.fill", fr("paywall.trial.today"), fr("paywall.trial.noPayment"), fr("paywall.trial.todayDetail")),
            ("bell.fill", fr("paywall.trial.in2days"), fr("paywall.trial.reminder"), fr("paywall.trial.reminderDetail")),
            ("star.fill", fr("paywall.trial.in3days"), fr("paywall.trial.starts"), fr("paywall.trial.startsDetail")),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(BrutalPalette.ink.opacity(0.15))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 18)

            Text(fr("paywall.trialSheet.title"))
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(BrutalPalette.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 28)
                .padding(.bottom, 22)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        VStack(spacing: 0) {
                            timelineIcon(step.icon)
                            if index < steps.count - 1 {
                                Rectangle()
                                    .fill(BrutalPalette.ink.opacity(0.16))
                                    .frame(width: 3, height: rowSpacing + 34)
                            }
                        }
                        .frame(width: iconColumnWidth)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(.system(.headline, design: .rounded, weight: .heavy))
                                .foregroundStyle(BrutalPalette.ink)
                            Text(step.subtitle)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                            Text(step.detail)
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(BrutalPalette.ink.opacity(0.65))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 2)
                        .padding(.bottom, index < steps.count - 1 ? rowSpacing : 0)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 12)

            Text(fr("paywall.cancelAnytime"))
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink.opacity(0.5))
                .padding(.horizontal, 28)
                .padding(.bottom, 8)

            OnboardingPrimaryButton(title: fr("paywall.trialSheet.start"), action: {
                OnboardingHaptics.primaryCTA()
                onContinue()
            })
            .padding(.bottom, -24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(PaywallDesign.background.ignoresSafeArea())
    }

    private func timelineIcon(_ icon: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(BrutalPalette.pink)
                .frame(width: iconColumnWidth, height: iconColumnWidth)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(BrutalPalette.ink, lineWidth: 2)
                }
            Image(systemName: icon)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(.white)
        }
    }

    private var paywallLanguage: AppLanguage {
        languageManager.current
    }

    private func fr(_ key: String) -> String {
        AppLocalizable.string(key, language: paywallLanguage)
    }
}

// MARK: - Flow layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
