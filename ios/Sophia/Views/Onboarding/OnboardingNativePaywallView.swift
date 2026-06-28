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
            let canvasHeight = PaywallDesign.s(PaywallFigmaLayout.scrollHeight, width: w)

            ZStack(alignment: .topTrailing) {
                PaywallDesign.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            Color.clear
                                .frame(width: w, height: canvasHeight)

                            paywallCanvas(width: w)
                        }
                        .frame(width: w, height: canvasHeight)
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

    // MARK: - Figma canvas (node 167:93)

    @ViewBuilder
    private func paywallCanvas(width w: CGFloat) -> some View {
        let s: (CGFloat) -> CGFloat = { PaywallDesign.s($0, width: w) }

        // Highlight bars (behind headlines)
        figmaHighlightBar(PaywallFigmaLayout.headerHighlight, color: PaywallDesign.highlightYellow, layoutWidth: w)
        figmaHighlightBar(PaywallFigmaLayout.weaponHighlight, color: PaywallDesign.highlightPink, layoutWidth: w)
        figmaHighlightBar(PaywallFigmaLayout.premiumHighlight, color: PaywallDesign.highlightYellow, layoutWidth: w)

        // Headlines
        figmaHeadline(
            textKey: "paywall.header",
            highlightKey: "paywall.header.highlight",
            fontSize: 34.071,
            lineHeight: 37.965,
            rect: PaywallFigmaLayout.headerText,
            layoutWidth: w
        )

        // Header stars + lightbulb
        figmaStar("paywall_star_1", rect: PaywallFigmaLayout.star1, layoutWidth: w)
        figmaStar("paywall_star_2", rect: PaywallFigmaLayout.star2, layoutWidth: w)

        Image("paywall_lightbulb")
            .resizable()
            .scaledToFit()
            .frame(width: s(PaywallFigmaLayout.lightbulb.width), height: s(PaywallFigmaLayout.lightbulb.height))
            .rotationEffect(.degrees(PaywallFigmaLayout.lightbulbRotation))
            .paywallFigmaRect(PaywallFigmaLayout.lightbulb, layoutWidth: w)

        subjectsCardCanvas(width: w)

        Image("paywall_pencil")
            .resizable()
            .scaledToFit()
            .frame(width: s(PaywallFigmaLayout.pencil.width), height: s(PaywallFigmaLayout.pencil.height))
            .rotationEffect(.degrees(PaywallFigmaLayout.pencilRotation))
            .paywallFigmaRect(PaywallFigmaLayout.pencil, layoutWidth: w)

        figmaStar("paywall_star_3", rect: PaywallFigmaLayout.star3, layoutWidth: w)
        figmaStar("paywall_star_4", rect: PaywallFigmaLayout.star4, layoutWidth: w)

        figmaHeadline(
            textKey: "paywall.weaponHeadline",
            highlightKey: "paywall.weaponHeadline.highlight",
            fontSize: 34.071,
            lineHeight: 37.965,
            rect: PaywallFigmaLayout.weaponText,
            layoutWidth: w
        )

        Image("paywall_phi")
            .resizable()
            .scaledToFit()
            .frame(width: s(PaywallFigmaLayout.phi.width), height: s(PaywallFigmaLayout.phi.height))
            .rotationEffect(.degrees(PaywallFigmaLayout.phiRotation))
            .paywallFigmaRect(PaywallFigmaLayout.phi, layoutWidth: w)

        figmaStar("paywall_star_5", rect: PaywallFigmaLayout.star5, layoutWidth: w)
        figmaStar("paywall_star_6", rect: PaywallFigmaLayout.star6, layoutWidth: w)

        ForEach(Array(PaywallFigmaLayout.benefits.enumerated()), id: \.offset) { _, benefit in
            benefitCardCanvas(benefit, layoutWidth: w)
        }

        figmaHeadline(
            textKey: "paywall.premiumHeadline",
            highlightKey: "paywall.premiumHeadline.highlight",
            fontSize: 34,
            lineHeight: 38,
            rect: PaywallFigmaLayout.premiumText,
            layoutWidth: w
        )

        featureComparison(width: w)
            .paywallFigmaRect(PaywallFigmaLayout.comparisonTable, layoutWidth: w)

        planCard(.yearly, width: w)
            .paywallFigmaRect(PaywallFigmaLayout.yearlyPlan, layoutWidth: w)

        planCard(.monthly, width: w)
            .paywallFigmaRect(PaywallFigmaLayout.monthlyPlan, layoutWidth: w)

        if selectedPlan == .yearly {
            let badge = prices.discountBadge ?? fr("paywall.plan.discount")
            Text(badge)
                .font(PaywallDesign.nunitoExtraBold(13.595, width: w))
                .foregroundStyle(BrutalPalette.ink)
                .frame(width: s(PaywallFigmaLayout.discountBadge.width), height: s(PaywallFigmaLayout.discountBadge.height))
                .background(PaywallDesign.accentPink, in: RoundedRectangle(cornerRadius: s(9.021), style: .continuous))
                .paywallFigmaRect(PaywallFigmaLayout.discountBadge, layoutWidth: w)
        }

        legalRow(width: w)
            .frame(maxWidth: .infinity)
            .paywallFigmaPosition(x: 0, y: PaywallFigmaLayout.legalRowY, layoutWidth: w)
    }

    private func figmaHighlightBar(_ rect: CGRect, color: Color, layoutWidth w: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: PaywallDesign.s(5, width: w), style: .continuous)
            .fill(color)
            .paywallFigmaRect(rect, layoutWidth: w)
    }

    private func figmaHeadline(
        textKey: String,
        highlightKey: String,
        fontSize: CGFloat,
        lineHeight: CGFloat,
        rect: CGRect,
        layoutWidth w: CGFloat
    ) -> some View {
        PaywallHighlightedHeadline(
            text: fr(textKey),
            highlight: "",
            fontSize: fontSize,
            lineHeight: lineHeight,
            highlightColor: .clear,
            layoutWidth: w
        )
        .frame(width: PaywallDesign.s(rect.width, width: w), alignment: .leading)
        .paywallFigmaRect(rect, layoutWidth: w)
    }

    private func figmaStar(_ name: String, rect: CGRect, layoutWidth w: CGFloat) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .paywallFigmaRect(rect, layoutWidth: w)
    }

    private func subjectsCardCanvas(width w: CGFloat) -> some View {
        let innerW = PaywallFigmaLayout.subjectsCardInner.width
        let innerH = PaywallFigmaLayout.subjectsCardInner.height
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
        .frame(width: PaywallDesign.s(innerW, width: w), height: PaywallDesign.s(innerH, width: w), alignment: .topLeading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
        .paywallFigmaShadow(corner: corner, depth: PaywallDesign.s(3, width: w))
        .rotationEffect(.degrees(PaywallFigmaLayout.subjectsCardRotation))
        .paywallFigmaRect(PaywallFigmaLayout.subjectsCard, layoutWidth: w)
    }

    private func benefitCardCanvas(_ benefit: PaywallFigmaLayout.Benefit, layoutWidth w: CGFloat) -> some View {
        let s: (CGFloat) -> CGFloat = { PaywallDesign.s($0, width: w) }

        return Color.clear
            .frame(width: s(benefit.width), height: s(benefit.height))
            .overlay {
                Text(fr(benefit.textKey))
                    .font(PaywallDesign.quicksandBold(13.67, width: w))
                    .foregroundStyle(BrutalPalette.ink)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, s(20))
                    .frame(width: s(benefit.cardWidth), height: s(benefit.cardHeight), alignment: .leading)
                    .background(benefit.color, in: RoundedRectangle(cornerRadius: s(13), style: .continuous))
                    .paywallFigmaShadow(
                        corner: s(13),
                        depth: s(2),
                        borderWidth: s(1.5)
                    )
                    .rotationEffect(.degrees(benefit.rotation))
            }
            .paywallFigmaPosition(x: benefit.x, y: benefit.y, layoutWidth: w)
    }

    // MARK: - Subjects

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

    // MARK: - Premium comparison

    private func featureComparison(width w: CGFloat) -> some View {
        let corner = PaywallDesign.s(17, width: w)
        let premiumRelX = PaywallFigmaLayout.premiumColumn.minX - PaywallFigmaLayout.comparisonTable.minX
        let premiumWidth = PaywallFigmaLayout.premiumColumn.width
        let premiumHeight = PaywallFigmaLayout.premiumColumn.height

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: PaywallDesign.s(14, width: w), style: .continuous)
                .fill(PaywallDesign.creamHighlight)
                .overlay {
                    RoundedRectangle(cornerRadius: PaywallDesign.s(14, width: w), style: .continuous)
                        .strokeBorder(PaywallDesign.orange, lineWidth: PaywallDesign.s(2, width: w))
                }
                .frame(
                    width: PaywallDesign.s(premiumWidth, width: w),
                    height: PaywallDesign.s(premiumHeight, width: w)
                )
                .offset(x: PaywallDesign.s(premiumRelX, width: w))

            VStack(spacing: 0) {
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
            .background(Color.white, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .paywallFigmaShadow(corner: corner, depth: PaywallDesign.s(3, width: w))
        }
        .frame(
            width: PaywallDesign.s(PaywallFigmaLayout.comparisonTable.width, width: w),
            height: PaywallDesign.s(PaywallFigmaLayout.comparisonTable.height, width: w),
            alignment: .topLeading
        )
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

    @ViewBuilder
    private func planCard(_ plan: Plan, width w: CGFloat) -> some View {
        let isSelected = selectedPlan == plan
        let isYearly = plan == .yearly
        let faded = !isSelected
        let corner = PaywallDesign.s(13, width: w)
        let cardW = PaywallDesign.s(PaywallFigmaLayout.yearlyPlan.width, width: w)
        let cardH = PaywallDesign.s(PaywallFigmaLayout.yearlyPlan.height, width: w)
        let bodyH = PaywallDesign.s(88, width: w)

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
                    .frame(height: PaywallDesign.s(29, width: w))
                    .background(
                        isYearly
                            ? PaywallDesign.orange
                            : PaywallDesign.orange.opacity(faded ? 0.4 : 1)
                    )

                HStack(spacing: PaywallDesign.s(14, width: w)) {
                    Image(isSelected ? "paywall_checkbox_on" : "paywall_checkbox_off")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: PaywallDesign.s(32, width: w),
                            height: PaywallDesign.s(32, width: w)
                        )
                        .opacity(faded ? 0.55 : 1)

                    VStack(alignment: .leading, spacing: PaywallDesign.s(4, width: w)) {
                        Text(isYearly ? fr("paywall.plan.yearly") : fr("paywall.plan.monthly"))
                            .font(PaywallDesign.productSans(17, width: w))
                            .foregroundStyle(BrutalPalette.ink.opacity(faded ? 0.5 : 1))
                        Text(isYearly ? prices.yearlyPerMonth : fr("paywall.plan.monthlySubtitle"))
                            .font(.system(size: PaywallDesign.s(11.051, width: w), weight: .regular, design: .default))
                            .foregroundStyle(BrutalPalette.ink.opacity(faded ? 0.35 : 0.6))
                    }

                    Spacer(minLength: PaywallDesign.s(8, width: w))

                    VStack(alignment: .trailing, spacing: PaywallDesign.s(4, width: w)) {
                        Text(isYearly ? prices.yearlyPrice : prices.monthlyPrice)
                            .font(PaywallDesign.productSans(17, width: w))
                            .foregroundStyle(BrutalPalette.ink.opacity(faded ? 0.5 : 1))
                        Text(isYearly ? fr("paywall.plan.perYear") : fr("paywall.plan.perMonth"))
                            .font(.system(size: PaywallDesign.s(11.051, width: w), weight: .regular, design: .default))
                            .foregroundStyle(BrutalPalette.ink.opacity(faded ? 0.35 : 0.6))
                    }
                }
                .padding(.horizontal, PaywallDesign.s(16, width: w))
                .padding(.vertical, PaywallDesign.s(14, width: w))
                .frame(width: cardW, height: bodyH, alignment: .leading)
                .background(isSelected && isYearly ? PaywallDesign.creamHighlight : Color.white)
            }
            .frame(width: cardW, height: cardH)
            .paywallFigmaShadow(
                corner: corner,
                depth: PaywallDesign.s(3, width: w),
                shadowColor: isYearly && isSelected ? PaywallDesign.orangeShadow : BrutalPalette.ink.opacity(0.3),
                borderColor: isSelected
                    ? (isYearly ? PaywallDesign.orange : BrutalPalette.ink)
                    : BrutalPalette.ink.opacity(0.3),
                borderWidth: PaywallDesign.s(2, width: w)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private func footer(width w: CGFloat) -> some View {
        VStack(spacing: PaywallDesign.s(8, width: w)) {
            Text(fr("paywall.cancelAnytime"))
                .font(.system(size: PaywallDesign.s(12, width: w), weight: .semibold, design: .rounded))
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
        .font(.system(size: PaywallDesign.s(13, width: w), weight: .semibold, design: .rounded))
        .foregroundStyle(BrutalPalette.ink.opacity(0.55))
        .buttonStyle(.plain)
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
