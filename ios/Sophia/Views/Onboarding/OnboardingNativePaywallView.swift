import Combine
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

    private var unlockedSubjects: Set<Subject> {
        FreemiumGate.unlockedSubjects(isPremium: false)
    }

    private var lockedSubjects: [Subject] {
        Subject.allCases.filter { !unlockedSubjects.contains($0) }
    }

    private var lockedCourseTeasers: [PaywallCourseTeaser] {
        let layouts: [PaywallTeaserLayout] = [.hero, .compact, .tall, .wide, .standard, .compact]
        var teasers: [PaywallCourseTeaser] = []
        var layoutIndex = 0

        for subject in lockedSubjects {
            let candidates = ContentCatalog.activeCourses.filter {
                $0.subject == subject && CourseImageMap.imageName(for: $0.id) != nil
            }
            for course in candidates.prefix(2) where layoutIndex < layouts.count {
                teasers.append(PaywallCourseTeaser(course: course, layout: layouts[layoutIndex]))
                layoutIndex += 1
            }
        }
        return teasers
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        header
                            .padding(.top, 8)

                        subjectsBlock
                            .padding(.horizontal, 24)

                        if !lockedCourseTeasers.isEmpty {
                            lockedCoursesTeaserBlock
                                .padding(.horizontal, 24)
                        }

                        featureComparison
                            .padding(.horizontal, 24)

                        VStack(spacing: 14) {
                            planCard(.yearly)
                            planCard(.monthly)
                        }
                        .padding(.horizontal, 24)

                        PaywallReviewsCarousel()
                            .padding(.horizontal, 24)

                        restoreRow
                            .padding(.bottom, 8)
                    }
                    .padding(.bottom, 12)
                }

                VStack(spacing: 8) {
                    Text(languageManager.text("paywall.cancelAnytime"))
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.5))

                    OnboardingPrimaryButton(title: store.isPurchasing ? languageManager.text("common.processing") : languageManager.text("common.continue")) {
                        guard !store.isPurchasing else { return }
                        OnboardingHaptics.primaryCTA()
                        showReminderSheet = true
                    }
                    .disabled(store.isPurchasing)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Spacer()
                    closeButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
        }
        .onAppear {
            store.logOnboardingPurchaseDiagnostics()
        }
        .sheet(isPresented: $showReminderSheet) {
            TrialTimelineSheet(
                onContinue: {
                    showReminderSheet = false
                    onPurchase(selectedPlan)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
    }

    // MARK: - Header

    private var header: some View {
        Text(languageManager.text("paywall.header"))
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .foregroundStyle(BrutalPalette.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 24)
    }

    // MARK: - Subjects

    private var subjectsBlock: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text(languageManager.text("paywall.freeSubjects"))
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                FlowLayout(spacing: 10) {
                    ForEach(Array(unlockedSubjects).sorted(by: { $0.localizedShortName(language: languageManager.current) < $1.localizedShortName(language: languageManager.current) }), id: \.self) { subject in
                        subjectPill(subject, locked: false)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(languageManager.text("paywall.lockedSubjects"))
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                FlowLayout(spacing: 10) {
                    ForEach(lockedSubjects, id: \.self) { subject in
                        subjectPill(subject, locked: true)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .brutalOnboardingCard(depth: 4, corner: 20)
    }

    private func subjectPill(_ subject: Subject, locked: Bool) -> some View {
        HStack(spacing: 8) {
            subjectIconBadge(subject: subject, locked: locked)
            Text(subject.localizedShortName(language: languageManager.current))
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .lineLimit(1)
        }
        .foregroundStyle(locked ? BrutalPalette.ink.opacity(0.5) : BrutalPalette.ink)
        .padding(.leading, 6)
        .padding(.trailing, 13)
        .padding(.vertical, 7)
        .background(locked ? Color(white: 0.95) : BrutalPalette.pastel(for: subject), in: Capsule())
        .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2) }
    }

    private func subjectIconBadge(subject: Subject, locked: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(locked ? Color.white : BrutalPalette.pastel(for: subject).opacity(0.55))
                .frame(width: 32, height: 32)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(BrutalPalette.ink, lineWidth: 2)
                }
            Image(systemName: locked ? "lock.fill" : subject.icon)
                .font(.system(size: locked ? 12 : 14, weight: .black))
                .foregroundStyle(BrutalPalette.ink)
                .symbolRenderingMode(.hierarchical)
        }
    }

    // MARK: - Locked course teasers

    private var lockedCoursesTeaserBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(languageManager.text("paywall.teaserTitle"))
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                Text(languageManager.text("paywall.teaserSubtitle"))
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.5))
            }

            lockedCourseTeaserCollage
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .brutalOnboardingCard(depth: 4, corner: 20)
    }

    @ViewBuilder
    private var lockedCourseTeaserCollage: some View {
        let teasers = lockedCourseTeasers
        VStack(alignment: .leading, spacing: 10) {
            if let first = teasers.first {
                if teasers.count == 1 {
                    courseTeaserCard(first)
                } else {
                    HStack(alignment: .top, spacing: 10) {
                        courseTeaserCard(first)
                        if teasers.count > 1 {
                            courseTeaserCard(teasers[1])
                        }
                    }
                }
            }
            if teasers.count > 2 {
                courseTeaserCard(teasers[2])
            }
            if teasers.count > 3 {
                HStack(alignment: .top, spacing: 10) {
                    courseTeaserCard(teasers[3])
                    if teasers.count > 4 {
                        courseTeaserCard(teasers[4])
                    }
                }
            }
            if teasers.count > 5 {
                courseTeaserCard(teasers[5])
            }
        }
    }

    private func courseTeaserCard(_ teaser: PaywallCourseTeaser) -> some View {
        let layout = teaser.layout
        let pastel = BrutalPalette.pastel(for: teaser.course.subject)

        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let image = CourseImageMap.loadImage(for: teaser.course.id) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        pastel
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: layout.imageHeight)
                .clipped()

                LinearGradient(
                    colors: [.clear, BrutalPalette.ink.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: layout.imageHeight * 0.55)

                Text(teaser.course.subject.localizedShortName(language: languageManager.current).uppercased())
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(BrutalPalette.ink.opacity(0.35), in: Capsule())
                    .padding(8)
            }

            Text(teaser.course.title)
                .font(.system(layout == PaywallTeaserLayout.compact ? .caption2 : .caption, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .lineLimit(layout == PaywallTeaserLayout.compact ? 2 : 3)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(pastel.opacity(0.55))
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: layout.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: layout.cornerRadius, style: .continuous)
                .strokeBorder(BrutalPalette.ink, lineWidth: 2)
        }
        .frame(maxWidth: layout.fixedWidth == nil ? .infinity : nil)
        .frame(width: layout.fixedWidth)
        .rotationEffect(.degrees(layout.rotation))
        .allowsHitTesting(false)
    }

    // MARK: - Feature comparison

    private var featureComparison: some View {
        VStack(spacing: 0) {
            HStack {
                Text(languageManager.text("paywall.featureColumn"))
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.5))
                Spacer()
                Text(languageManager.text("paywall.freeColumn"))
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.5))
                    .frame(width: 56)
                Text(languageManager.text("paywall.premiumColumn"))
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .frame(width: 72)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().overlay(BrutalPalette.ink.opacity(0.15))

            featureRow(languageManager.text("paywall.feature.3subjects"), free: true, premium: true)
            featureRow(languageManager.text("paywall.feature.allSubjects"), free: false, premium: true)
            featureRow(languageManager.text("paywall.feature.unlimitedCourses"), free: false, premium: true)
            featureRow(languageManager.text("paywall.feature.miniQuiz"), free: false, premium: true)
            featureRow(languageManager.text("paywall.feature.fullLibrary"), free: false, premium: true)
        }
        .brutalOnboardingCard(depth: 3, corner: 18)
    }

    private func featureRow(_ title: String, free: Bool, premium: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink)
            Spacer()
            featureCheck(free).frame(width: 56)
            featureCheck(premium).frame(width: 72)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func featureCheck(_ on: Bool) -> some View {
        Group {
            if on {
                ZStack {
                    Circle().fill(BrutalPalette.yellow).frame(width: 22, height: 22)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                }
            } else {
                Text("—")
                    .font(.system(.subheadline, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.25))
            }
        }
    }

    // MARK: - Plan card

    private func package(for plan: Plan) -> Package? {
        plan == .yearly ? store.annualPackage : store.monthlyPackage
    }

    private func planCopy(for plan: Plan) -> (title: String, subtitle: String, price: String, period: String, badge: String?) {
        let isYearly = plan == .yearly
        let lang = languageManager.current
        guard let pkg = package(for: plan) else {
            return (
                isYearly ? AppLocalizable.string("paywall.plan.yearly", language: lang) : AppLocalizable.string("paywall.plan.monthly", language: lang),
                isYearly ? AppLocalizable.string("paywall.plan.fallback.yearlyMonthly", language: lang) : AppLocalizable.string("paywall.plan.monthlySubtitle", language: lang),
                isYearly ? AppLocalizable.string("paywall.plan.fallback.yearlyPrice", language: lang) : AppLocalizable.string("paywall.plan.fallback.monthlyPrice", language: lang),
                isYearly ? AppLocalizable.string("paywall.plan.perYear", language: lang) : AppLocalizable.string("paywall.plan.perMonth", language: lang),
                isYearly ? AppLocalizable.string("paywall.plan.discount", language: lang) : nil
            )
        }

        let price = pkg.localizedPriceString
        if isYearly {
            return (
                AppLocalizable.string("paywall.plan.yearly", language: lang),
                AppLocalizable.string("paywall.plan.yearlySubtitle", language: lang),
                price,
                AppLocalizable.string("paywall.plan.perYear", language: lang),
                AppLocalizable.string("paywall.plan.discount", language: lang)
            )
        }
        return (
            AppLocalizable.string("paywall.plan.monthly", language: lang),
            AppLocalizable.string("paywall.plan.monthlySubtitle", language: lang),
            price,
            AppLocalizable.string("paywall.plan.perMonth", language: lang),
            nil
        )
    }

    @ViewBuilder
    private func planCard(_ plan: Plan) -> some View {
        let isSelected = selectedPlan == plan
        let isYearly = plan == .yearly
        let tint: Color = isYearly ? OnboardingPastels.at(3) : OnboardingPastels.at(1)
        let copy = planCopy(for: plan)
        let cardCorner: CGFloat = 14

        Button {
            OnboardingHaptics.planSelected()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedPlan = plan
            }
        } label: {
            VStack(spacing: 0) {
                Text(languageManager.text("paywall.trialBadge"))
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(BrutalPalette.yellow)

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                            .frame(width: 26, height: 26)
                        if isSelected {
                            Circle()
                                .fill(BrutalPalette.yellow)
                                .frame(width: 26, height: 26)
                                .overlay {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundStyle(BrutalPalette.ink)
                                }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(copy.title)
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                        Text(copy.subtitle)
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.6))
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(copy.price)
                            .font(.system(.title3, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                        Text(copy.period)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                    }

                    if let badge = copy.badge {
                        Text(badge)
                            .font(.system(.caption2, design: .rounded, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(BrutalPalette.ink, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isSelected ? tint : Color.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                    .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
            }
        }
        .buttonStyle(PlanCardButtonStyle())
    }

    private var restoreRow: some View {
        Button {
            OnboardingHaptics.selection()
            onRestore()
        } label: {
            Text(languageManager.text("paywall.restoreRow"))
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(BrutalPalette.ink.opacity(0.55))
        }
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
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
                .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2) }
        }
        .accessibilityLabel(languageManager.text("common.close"))
    }
}

// MARK: - Course teaser models

private struct PaywallCourseTeaser: Identifiable {
    let course: Course
    let layout: PaywallTeaserLayout
    var id: String { course.id }
}

private struct PaywallTeaserLayout: Equatable {
    let imageHeight: CGFloat
    let cornerRadius: CGFloat
    let fixedWidth: CGFloat?
    let isFullWidth: Bool
    let rotation: Double

    static let hero = PaywallTeaserLayout(imageHeight: 128, cornerRadius: 16, fixedWidth: nil, isFullWidth: true, rotation: -0.6)
    static let compact = PaywallTeaserLayout(imageHeight: 72, cornerRadius: 14, fixedWidth: 112, isFullWidth: false, rotation: 1.8)
    static let tall = PaywallTeaserLayout(imageHeight: 108, cornerRadius: 15, fixedWidth: nil, isFullWidth: false, rotation: -1.2)
    static let wide = PaywallTeaserLayout(imageHeight: 92, cornerRadius: 16, fixedWidth: nil, isFullWidth: true, rotation: 0.4)
    static let standard = PaywallTeaserLayout(imageHeight: 86, cornerRadius: 14, fixedWidth: nil, isFullWidth: false, rotation: -0.8)
}

// MARK: - Reviews carousel

private struct PaywallReviewsCarousel: View {
    @Environment(LanguageManager.self) private var languageManager

    private struct Review: Identifiable {
        let id = UUID()
        let quote: String
        let author: String
    }

    private var reviews: [Review] {
        [
            Review(quote: languageManager.text("paywall.review1.quote"), author: languageManager.text("paywall.review1.author")),
            Review(quote: languageManager.text("paywall.review2.quote"), author: languageManager.text("paywall.review2.author")),
            Review(quote: languageManager.text("paywall.review3.quote"), author: languageManager.text("paywall.review3.author")),
            Review(quote: languageManager.text("paywall.review4.quote"), author: languageManager.text("paywall.review4.author")),
            Review(quote: languageManager.text("paywall.review5.quote"), author: languageManager.text("paywall.review5.author")),
        ]
    }

    @State private var index: Int = 0
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(BrutalPalette.yellow)
                }
            }

            TabView(selection: $index) {
                ForEach(Array(reviews.enumerated()), id: \.element.id) { offset, review in
                    VStack(spacing: 8) {
                        Text("\"\(review.quote)\"")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .italic()
                            .fixedSize(horizontal: false, vertical: true)

                        Text(review.author)
                            .font(.system(.caption, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.45))
                    }
                    .padding(.horizontal, 4)
                    .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 108)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .brutalOnboardingCard(depth: 3, corner: 18)
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.45)) {
                index = (index + 1) % reviews.count
            }
        }
    }
}

// MARK: - Trial timeline sheet

private struct TrialTimelineSheet: View {
    @Environment(LanguageManager.self) private var languageManager
    let onContinue: () -> Void

    private var steps: [(icon: String, title: String, subtitle: String, detail: String)] {
        [
            ("lock.open.fill", languageManager.text("paywall.trial.today"), languageManager.text("paywall.trial.noPayment"), languageManager.text("paywall.trial.todayDetail")),
            ("bell.fill", languageManager.text("paywall.trial.in2days"), languageManager.text("paywall.trial.reminder"), languageManager.text("paywall.trial.reminderDetail")),
            ("star.fill", languageManager.text("paywall.trial.in3days"), languageManager.text("paywall.trial.starts"), languageManager.text("paywall.trial.startsDetail")),
        ]
    }

    private let iconColumnWidth: CGFloat = 42
    private let connectorHeight: CGFloat = 12

    var body: some View {
        VStack(spacing: 0) {
            Text(languageManager.text("paywall.trialSheet.title"))
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        TrialTimelineStepRow(
                            icon: step.icon,
                            title: step.title,
                            subtitle: step.subtitle,
                            detail: step.detail,
                            iconColumnWidth: iconColumnWidth
                        )

                        if index < steps.count - 1 {
                            timelineConnector
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)

                Text(languageManager.text("paywall.cancelAnytime"))
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.5))
                    .padding(.leading, iconColumnWidth + 14)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 24)

            Spacer(minLength: 24)

            OnboardingPrimaryButton(title: languageManager.text("paywall.trialSheet.start"), action: {
                OnboardingHaptics.primaryCTA()
                onContinue()
            })
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(BrutalPalette.cream.ignoresSafeArea())
    }

    private var timelineConnector: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(BrutalPalette.ink.opacity(0.18))
                .frame(width: 3, height: connectorHeight)
                .frame(width: iconColumnWidth)
            Spacer(minLength: 0)
        }
    }
}

private struct TrialTimelineStepRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let detail: String
    let iconColumnWidth: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
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
            .frame(width: iconColumnWidth, height: iconColumnWidth)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)

                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.55))

                Text(detail)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Flow layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
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
