import SwiftUI
import RevenueCat

struct OnboardingNativePaywallView: View {
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

    private let paywallLanguage: AppLanguage = .french
    private let legalURL = URL(string: "https://vikstudios.com/sophia")!

    private var unlockedSubjects: Set<Subject> {
        FreemiumGate.unlockedSubjects(isPremium: false)
    }

    private var lockedSubjects: [Subject] {
        Subject.allCases.filter { !unlockedSubjects.contains($0) }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PaywallDesign.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        header
                            .padding(.top, 56)

                        subjectsSection
                            .padding(.horizontal, 20)

                        boostSection
                            .padding(.horizontal, 20)

                        premiumSection
                            .padding(.horizontal, 20)

                        VStack(spacing: 14) {
                            planCard(.yearly)
                            planCard(.monthly)
                        }
                        .padding(.horizontal, 20)

                        legalRow
                            .padding(.bottom, 8)
                    }
                    .padding(.bottom, 12)
                }

                footer
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Spacer()
                closeButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
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
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showLegalSafari) {
            InAppSafariView(url: legalURL)
                .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack(alignment: .topTrailing) {
            highlightedHeadline(
                full: fr("paywall.header"),
                highlight: fr("paywall.header.highlight"),
                highlightColor: PaywallDesign.orange,
                fontSize: 32,
                lineSpacing: 4
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            PaywallLightbulbView(size: 52)
                .rotationEffect(.degrees(12))
                .offset(x: -8, y: -18)
        }
    }

    // MARK: - Subjects

    private var subjectsSection: some View {
        ZStack {
            freeSubjectsCard
                .rotationEffect(.degrees(3.27))
                .offset(y: -28)
                .zIndex(1)

            PaywallStarCluster()
                .offset(y: 52)
                .zIndex(2)

            lockedSubjectsCard
                .rotationEffect(.degrees(-3.27))
                .offset(y: 118)
                .zIndex(0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .padding(.bottom, 24)
    }

    private var freeSubjectsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(fr("paywall.freeSubjects"))
                .font(.system(size: 19.5, weight: .black, design: .rounded))
                .foregroundStyle(BrutalPalette.ink)

            FlowLayout(spacing: 10) {
                ForEach(Array(unlockedSubjects).sorted(by: subjectSort), id: \.self) { subject in
                    subjectPill(subject, locked: false)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paywallBrutalCard()
        .overlay(alignment: .top) {
            PaywallGreyStarBadge()
                .offset(y: -24)
        }
    }

    private var lockedSubjectsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(fr("paywall.lockedSubjects"))
                .font(.system(size: 19.5, weight: .black, design: .rounded))
                .foregroundStyle(BrutalPalette.ink)

            FlowLayout(spacing: 10) {
                ForEach(lockedSubjects, id: \.self) { subject in
                    subjectPill(subject, locked: true)
                }
            }
            .opacity(0.5)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paywallBrutalCard()
    }

    private func subjectPill(_ subject: Subject, locked: Bool) -> some View {
        let label = subject.localizedShortName(language: paywallLanguage)
        let text = locked ? "🔒 \(label)" : "\(subject.emoji) \(label)"

        return Text(text)
            .font(.system(size: 14.5, weight: .bold, design: .rounded))
            .foregroundStyle(BrutalPalette.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                locked ? PaywallDesign.lockedPill : PaywallDesign.freePillColor(for: subject),
                in: Capsule()
            )
            .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 3) }
            .shadow(color: BrutalPalette.ink, radius: 0, x: 1, y: 1)
    }

    // MARK: - Boost

    private var boostSection: some View {
        ZStack {
            PaywallBlobShape()
                .fill(PaywallDesign.bubbleBlue.opacity(0.85))
                .frame(width: 68, height: 58)
                .rotationEffect(.degrees(-8))
                .offset(x: -118, y: 34)

            PaywallBlobShape()
                .fill(PaywallDesign.bubblePurple.opacity(0.9))
                .frame(width: 88, height: 68)
                .rotationEffect(.degrees(8))
                .offset(x: 96, y: 18)

            PaywallStarShape()
                .fill(PaywallDesign.bubbleOrange)
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(-12))
                .offset(x: -118, y: 108)

            VStack(spacing: 18) {
                highlightedHeadline(
                    full: fr("paywall.boostHeadline"),
                    highlight: fr("paywall.boostHeadline.highlight"),
                    highlightColor: PaywallDesign.accentPink,
                    fontSize: 30,
                    lineSpacing: 2
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    PaywallSpeechPill(title: fr("paywall.boostBubble.conversations"), fill: PaywallDesign.bubbleBlue)
                        .offset(x: -52, y: -8)
                    PaywallSpeechPill(title: fr("paywall.boostBubble.curiosity"), fill: PaywallDesign.bubblePurple)
                        .offset(x: 48, y: 28)
                    PaywallSpeechPill(title: fr("paywall.boostBubble.confidence"), fill: PaywallDesign.bubbleOrange)
                        .offset(x: -36, y: 72)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Premium comparison

    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            highlightedHeadline(
                full: fr("paywall.premiumHeadline"),
                highlight: fr("paywall.premiumHeadline.highlight"),
                highlightColor: PaywallDesign.orange,
                fontSize: 30,
                lineSpacing: 2
            )

            ZStack(alignment: .top) {
                featureComparison
                PaywallStarCluster()
                    .offset(y: -22)
            }
        }
    }

    private var featureComparison: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(PaywallDesign.creamHighlight)
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .strokeBorder(PaywallDesign.orange, lineWidth: 3)
                }
                .frame(width: 78)
                .padding(.top, 44)
                .padding(.trailing, 3)
                .padding(.bottom, 3)

            VStack(spacing: 0) {
                HStack {
                    Text(fr("paywall.featureColumn"))
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(BrutalPalette.ink)
                    Spacer()
                    Text(fr("paywall.freeColumn"))
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(BrutalPalette.ink)
                        .frame(width: 52)
                    Text(fr("paywall.premiumColumn"))
                        .font(.system(size: 9.5, weight: .black, design: .rounded))
                        .foregroundStyle(BrutalPalette.ink)
                        .frame(width: 72)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                featureRow(fr("paywall.feature.3subjects"), free: .freeCheck, premium: .premiumCheck)
                featureRow(fr("paywall.feature.allSubjects"), free: .denied, premium: .premiumCheck)
                featureRow(fr("paywall.feature.unlimitedCourses"), free: .denied, premium: .premiumCheck)
                featureRow(fr("paywall.feature.miniQuiz"), free: .denied, premium: .premiumCheck)
                featureRow(fr("paywall.feature.fullLibrary"), free: .denied, premium: .premiumCheck)
            }
            .paywallBrutalCard()
        }
    }

    private func featureRow(_ title: String, free: PaywallFeatureMark.Kind, premium: PaywallFeatureMark.Kind) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                .foregroundStyle(BrutalPalette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            PaywallFeatureMark(kind: free)
                .frame(width: 52)
            PaywallFeatureMark(kind: premium)
                .frame(width: 72)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }

    // MARK: - Plans

    private func package(for plan: Plan) -> Package? {
        plan == .yearly ? store.annualPackage : store.monthlyPackage
    }

    private func planCopy(for plan: Plan) -> (title: String, subtitle: String, price: String, period: String, badge: String?) {
        let isYearly = plan == .yearly
        guard let pkg = package(for: plan) else {
            return (
                isYearly ? fr("paywall.plan.yearly") : fr("paywall.plan.monthly"),
                isYearly ? fr("paywall.plan.fallback.yearlyMonthly") : fr("paywall.plan.monthlySubtitle"),
                isYearly ? fr("paywall.plan.fallback.yearlyPrice") : fr("paywall.plan.fallback.monthlyPrice"),
                isYearly ? fr("paywall.plan.perYear") : fr("paywall.plan.perMonth"),
                isYearly ? fr("paywall.plan.discount") : nil
            )
        }

        let price = pkg.localizedPriceString
        if isYearly {
            return (
                fr("paywall.plan.yearly"),
                fr("paywall.plan.fallback.yearlyMonthly"),
                price,
                fr("paywall.plan.perYear"),
                fr("paywall.plan.discount")
            )
        }
        return (
            fr("paywall.plan.monthly"),
            fr("paywall.plan.monthlySubtitle"),
            price,
            fr("paywall.plan.perMonth"),
            nil
        )
    }

    @ViewBuilder
    private func planCard(_ plan: Plan) -> some View {
        let isSelected = selectedPlan == plan
        let isYearly = plan == .yearly
        let copy = planCopy(for: plan)
        let accentBorder = isSelected ? (isYearly ? PaywallDesign.orange : BrutalPalette.ink) : BrutalPalette.ink
        let accentShadow = isSelected && isYearly ? PaywallDesign.orange : BrutalPalette.ink
        let bodyFill = isSelected && isYearly ? PaywallDesign.creamHighlight : Color.white
        let bodyBorderWidth: CGFloat = isSelected ? (isYearly ? 4 : 3.5) : 3

        Button {
            OnboardingHaptics.planSelected()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedPlan = plan
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    Text(fr("paywall.trialBadge"))
                        .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(BrutalPalette.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(PaywallDesign.orange)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(accentBorder)
                                .frame(height: 3)
                        }

                    HStack(spacing: 14) {
                        PaywallPlanRadio(isSelected: isSelected)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(copy.title)
                                .font(.system(size: 21.5, weight: .heavy, design: .rounded))
                                .foregroundStyle(BrutalPalette.ink)
                            Text(copy.subtitle)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(BrutalPalette.ink.opacity(0.6))
                        }

                        Spacer(minLength: 8)

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(copy.price)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(BrutalPalette.ink)
                            Text(copy.period)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(BrutalPalette.ink.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(bodyFill)
                }
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .strokeBorder(accentBorder, lineWidth: bodyBorderWidth)
                }
                .background(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(accentShadow)
                        .offset(x: 3, y: 3)
                }
                .padding(.bottom, 3)
                .padding(.trailing, 3)

                if isYearly, let badge = copy.badge {
                    PaywallDiscountBadge(text: badge)
                        .offset(x: 10, y: 36)
                }
            }
        }
        .buttonStyle(PlanCardButtonStyle())
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            Text(fr("paywall.cancelAnytime"))
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink.opacity(0.5))

            OnboardingPrimaryButton(title: store.isPurchasing ? fr("common.processing") : fr("common.continue")) {
                guard !store.isPurchasing else { return }
                showReminderSheet = true
            }
            .disabled(store.isPurchasing)
        }
    }

    private var legalRow: some View {
        HStack(spacing: 6) {
            Button("Restaurer", action: onRestore)
            Text("·")
            Button("Conditions") { showLegalSafari = true }
            Text("·")
            Button("Confidentialité") { showLegalSafari = true }
        }
        .font(.system(.footnote, design: .rounded, weight: .semibold))
        .foregroundStyle(BrutalPalette.ink.opacity(0.55))
        .buttonStyle(.plain)
    }

    private var closeButton: some View {
        Button {
            OnboardingHaptics.selection()
            onClose()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(BrutalPalette.ink)
                .frame(width: 42, height: 42)
                .background(Color.white)
                .clipShape(Circle())
                .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 3) }
                .shadow(color: BrutalPalette.ink, radius: 0, x: 3, y: 1)
        }
        .accessibilityLabel(fr("common.close"))
    }

    // MARK: - Helpers

    private func fr(_ key: String) -> String {
        AppLocalizable.string(key, language: paywallLanguage)
    }

    private func subjectSort(_ lhs: Subject, _ rhs: Subject) -> Bool {
        lhs.localizedShortName(language: paywallLanguage) < rhs.localizedShortName(language: paywallLanguage)
    }

    private func highlightedHeadline(
        full: String,
        highlight: String,
        highlightColor: Color,
        fontSize: CGFloat,
        lineSpacing: CGFloat
    ) -> some View {
        let parts = full.components(separatedBy: highlight)
        return (
            Text(parts.first ?? "")
                .foregroundStyle(BrutalPalette.ink)
            + Text(highlight)
                .foregroundStyle(highlightColor)
            + Text(parts.count > 1 ? parts.dropFirst().joined(separator: highlight) : "")
                .foregroundStyle(BrutalPalette.ink)
        )
        .font(.system(size: fontSize, weight: .black, design: .rounded))
        .lineSpacing(lineSpacing)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Trial timeline sheet

private struct PaywallTrialTimelineSheet: View {
    let onContinue: () -> Void

    private let paywallLanguage: AppLanguage = .french
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

            Text(fr("paywall.cancelAnytime"))
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink.opacity(0.5))
                .padding(.top, 16)
                .padding(.horizontal, 28)

            OnboardingPrimaryButton(title: fr("paywall.trialSheet.start"), action: {
                OnboardingHaptics.primaryCTA()
                onContinue()
            })
            .padding(.top, 12)
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
